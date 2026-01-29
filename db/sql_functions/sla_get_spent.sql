-- Calculate the total elapsed business minutes for a specific issue and SLA type
CREATE OR REPLACE FUNCTION sla_get_spent(
  p_issue_id INTEGER,
  p_sla_type_id INTEGER
)
  RETURNS sla_cache_spents AS
$BODY$
  DECLARE v_issue_project_id INTEGER ;
  DECLARE v_issue_tracker_id INTEGER ;
  DECLARE v_issue_created_on TIMESTAMP WITHOUT TIME ZONE ;
  DECLARE v_issue_closed_on TIMESTAMP WITHOUT TIME ZONE ;
  DECLARE v_current_timestamp TIMESTAMP WITHOUT TIME ZONE ;
  DECLARE v_sla_cache sla_caches ;
  DECLARE v_sla_spent sla_cache_spents ;
  DECLARE v_sla_level_terms sla_level_terms ;
BEGIN

  RAISE DEBUG 
    'sla_get_spent	BEGIN ---' ;

  -- Mandatory parameters check: abort if issue ID or SLA type ID is missing
  IF ( ( p_issue_id IS NULL ) OR ( p_sla_type_id IS NULL ) ) THEN
    RETURN NULL ;
  END IF ;

  -- Normalize current timestamp using the SLA-specific date utility
  v_current_timestamp := sla_get_date(NOW()::TIMESTAMP WITHOUT TIME ZONE);

  RAISE DEBUG
    'sla_get_spent	v_current_timestamp = %', v_current_timestamp ;

  -- Identify the current SLA level applied to this issue
  v_sla_cache := sla_get_level( p_issue_id ) ;

  -- Exit if the issue is not governed by any SLA level
  IF ( v_sla_cache IS NULL ) THEN
    RETURN NULL ;
  END IF ;

  -- Retrieve the specific terms (thresholds/rules) for this SLA type and level
  SELECT
    *
  INTO
    v_sla_level_terms
  FROM
    "sla_level_terms"
  WHERE
    "sla_level_terms"."sla_level_id" = v_sla_cache."sla_level_id"
  AND
    "sla_level_terms"."sla_type_id" = p_sla_type_id
  LIMIT 1 ;
  
  -- Abort if no calculation rules are defined for this specific SLA type
  IF ( v_sla_level_terms IS NULL ) THEN
      RETURN NULL;
  END IF ;
	
  -- Check if a spent time record already exists in the cache for this issue and SLA type
  SELECT
    "sla_cache_spents"."id" AS "id",
    "sla_cache_spents"."sla_cache_id" AS "sla_cache_id",
    "sla_cache_spents"."project_id" AS "project_id",
    "sla_cache_spents"."issue_id" AS "issue_id",
    "sla_cache_spents"."sla_type_id" AS "sla_type_id",
    "sla_cache_spents"."spent" AS "spent",
    "sla_cache_spents"."updated_on" AS "created_on",
    "sla_cache_spents"."updated_on" AS "updated_on"
  INTO	
    v_sla_spent
  FROM
    "sla_cache_spents"
  WHERE
    "sla_cache_spents"."sla_cache_id" = v_sla_cache.id 
  AND 
    "sla_cache_spents"."sla_type_id" = p_sla_type_id
  ;  

  -- Optimization: If the cache was already updated during this transaction/timestamp, skip recalculation
  IF ( ( v_sla_spent IS NOT NULL ) AND ( v_sla_spent."updated_on" IS NOT NULL ) AND ( v_sla_spent."updated_on" = "v_current_timestamp" ) ) THEN
    RETURN v_sla_spent ;
  END IF ;

  -- Determine the calculation window: from the last cache update (or SLA start) to the closing date (or now)
  SELECT
    COALESCE( v_sla_spent."updated_on", v_sla_cache."start_date" ),
    COALESCE( sla_get_date("issues"."closed_on"), v_current_timestamp ),
    tracker_id,
    project_id
  INTO
    v_issue_created_on,
    v_issue_closed_on,
    v_issue_tracker_id,
    v_issue_project_id
  FROM
    issues 
  WHERE
    id = p_issue_id
  ;

  -- Prevent redundant updates if the cache is already newer than the issue's closing date
  IF ( v_sla_spent."updated_on" > v_issue_closed_on ) THEN
    UPDATE "sla_cache_spents"
    SET "updated_on" = v_current_timestamp
    WHERE "sla_cache_spents"."sla_cache_id" = v_sla_spent."sla_cache_id"
    AND "sla_cache_spents"."sla_type_id" = v_sla_spent."sla_type_id" ;
    RETURN v_sla_spent ;
  END IF ;
	
  -- CORE CALCULATION:
  -- 1. Generate a 1-minute series between start and end dates.
  -- 2. Filter minutes based on issue status history (roll_statuses).
  -- 3. Intersect with Business Hours (schedules) and Calendar rules.
  -- 4. Exclude public holidays.
  SELECT DISTINCT
    NULL::integer AS "id",
    COALESCE( v_sla_spent."sla_cache_id", v_sla_cache."id" ) AS "sla_cache_id",
    v_issue_project_id AS "sla_project_id",
    p_issue_id AS "issue_id",
    p_sla_type_id AS "sla_type_id",
    COUNT(*) AS "spent",
    v_current_timestamp AS "created_on",
    v_current_timestamp AS "updated_on"
  INTO
    v_sla_spent
  FROM
    "issues"
  INNER JOIN
    "sla_view_roll_statuses" ON ( "issues"."id" = "sla_view_roll_statuses"."issue_id" )
  INNER JOIN
    ( SELECT generate_series ( v_issue_created_on, v_issue_closed_on, '1 minute' ) AS minutes ) AS "calendrier"
      ON ( "calendrier"."minutes" BETWEEN "sla_view_roll_statuses"."from_status_date" AND "sla_view_roll_statuses"."to_status_date" - INTERVAL '1 minute' )
  INNER JOIN
    "sla_schedules"
      ON ( DATE_PART('dow',calendrier.minutes) = "sla_schedules"."dow" AND "calendrier"."minutes"::TIME BETWEEN "sla_schedules"."start_time" AND "sla_schedules"."end_time" )
  INNER JOIN
    "sla_calendars"
      ON ( "sla_calendars"."id" = "sla_schedules"."sla_calendar_id" )
  INNER JOIN
    "sla_levels"
      ON ( "sla_levels"."sla_calendar_id" = "sla_calendars"."id" AND "sla_levels"."id" = v_sla_cache.sla_level_id ) 
  INNER JOIN
    "sla_project_trackers"
      ON ( "sla_project_trackers"."sla_id" = "sla_levels"."sla_id" )
  WHERE
    "issues"."id" = p_issue_id		
  AND
    "sla_view_roll_statuses"."from_status_id" IN ( SELECT DISTINCT "sla_statuses"."status_id" FROM "sla_statuses" WHERE "sla_statuses"."sla_type_id" = p_sla_type_id )
  AND
    "sla_project_trackers"."project_id" = "issues"."project_id"
  AND
    "sla_project_trackers"."tracker_id" = "issues"."tracker_id"
  AND
    -- Exclude dates defined in the holiday calendar
    DATE_TRUNC('day',"calendrier"."minutes") NOT IN ( 
      SELECT "sla_holidays"."date"
      FROM "sla_holidays"
      INNER JOIN "sla_calendar_holidays"
      ON ( "sla_calendar_holidays"."sla_holiday_id" = "sla_holidays"."id" ) 
      WHERE "sla_calendar_holidays"."sla_calendar_id" = "sla_calendars"."id"
      AND NOT "sla_calendar_holidays"."match"
    )
  ;  

  -- Safety check: Spent time cannot be negative
  IF ( v_sla_spent."spent" < 0 ) THEN 
    v_sla_spent."spent" := 0 ;
  END IF ;

  -- Persist the results: Insert new record or increment 'spent' minutes on conflict
  INSERT INTO sla_cache_spents (
    "sla_cache_id",
    "project_id",
    "issue_id",
    "sla_type_id",
    "spent",
    "created_on",
    "updated_on"
  ) VALUES (
    v_sla_spent."sla_cache_id",
    v_sla_spent."project_id",
    v_sla_spent."issue_id",
    v_sla_spent."sla_type_id",
    v_sla_spent."spent",
    v_sla_spent."created_on",
    v_sla_spent."updated_on"
  )
  -- Upsert logic: add new spent minutes to existing total
  ON CONFLICT ON CONSTRAINT "sla_cache_spents_sla_caches_sla_types_ukey" DO UPDATE SET
    "updated_on" = v_sla_spent."updated_on",
    "spent" = "sla_cache_spents"."spent" + v_sla_spent."spent"
  RETURNING id INTO v_sla_spent."id" ;

  RAISE DEBUG
    'sla_get_spent	END ------' ;
	
  RETURN v_sla_spent ;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;