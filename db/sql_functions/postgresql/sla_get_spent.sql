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
  -- 1. Generate one row per CALENDAR DAY between start and end dates (not per
  --    minute: a status interval can span years, and PostgreSQL's planner
  --    already handles per-minute generate_series fairly well, but summing a
  --    closed-form per-day intersection length is dramatically cheaper for
  --    long-lived issues while producing the exact same total).
  -- 2. For each day, intersect that day's business-hours window (schedules)
  --    with the issue's status-history intervals (roll_statuses) and the
  --    calculation window itself, and sum the resulting minute counts.
  -- 3. Exclude public holidays.
  WITH "issue_journal_statuses" AS (
    -- Inlined, per-issue copy of sla_view_journal_statuses/sla_view_roll_statuses
    -- (see db/sql_views/postgresql/) instead of joining those global views.
    -- Both views are themselves a UNION of two branches, so joining
    -- sla_view_roll_statuses here meant PostgreSQL re-ran this whole
    -- window-function computation up to four times (2 branches x 2 nested
    -- levels) per call, just to read back the status history of the ONE
    -- issue being processed -- confirmed via EXPLAIN ANALYZE as the
    -- dominant cost of this function for issues with any journal history.
    -- Scoping by p_issue_id up front and computing it once in a CTE (which
    -- PostgreSQL materializes here since it is referenced twice below)
    -- removes that redundancy entirely.
    (
      SELECT DISTINCT issues.id AS issue_id,
        sla_get_date(first_value(issues.created_on) OVER window_journals) AS issue_created_on,
        sla_get_date(first_value(issues.closed_on) OVER window_journals) AS issue_closed_on,
        sla_get_date(first_value(issues.created_on) OVER window_journals) AS journals_created_on,
        COALESCE(first_value(journal_details.old_value::integer) OVER window_journals, issues.status_id) AS journal_detail_old_value,
        COALESCE(first_value(journal_details.old_value::integer) OVER window_journals, issues.status_id) AS journal_detail_value
      FROM issues
      LEFT JOIN journals ON ( issues.id = journals.journalized_id )
      LEFT JOIN journal_details ON ( journals.id = journal_details.journal_id AND journal_details.property LIKE 'attr' AND journal_details.prop_key LIKE 'status_id' )
      WHERE issues.id = p_issue_id
      WINDOW window_journals AS ( PARTITION BY issues.id ORDER BY journal_details.id ASC NULLS LAST )
    ) UNION (
      SELECT issues.id AS issue_id,
        sla_get_date(issues.created_on) AS issue_created_on,
        sla_get_date(issues.closed_on) AS issue_closed_on,
        sla_get_date(journals.created_on) AS journals_created_on,
        journal_details.old_value::integer AS journal_detail_old_value,
        journal_details.value::integer AS journal_detail_value
      FROM issues
      INNER JOIN journals ON ( issues.id = journals.journalized_id )
      INNER JOIN journal_details ON ( journals.id = journal_details.journal_id AND journal_details.property LIKE 'attr' AND journal_details.prop_key LIKE 'status_id' )
      WHERE issues.id = p_issue_id
    )
  ),
  "issue_roll_statuses" AS (
    (
      SELECT
        issue_id AS issue_id,
        journal_detail_old_value AS from_status_id,
        LAG(journals_created_on, 1, issue_created_on) OVER window_status AS from_status_date,
        journal_detail_value AS to_status_id,
        journals_created_on AS to_status_date
      FROM issue_journal_statuses
      WINDOW window_status AS ( PARTITION BY issue_id ORDER BY journals_created_on ASC )
    ) UNION (
      SELECT
        issue_id AS issue_id,
        FIRST_VALUE(journal_detail_value) OVER window_status AS from_status_id,
        FIRST_VALUE(journals_created_on) OVER window_status AS from_status_date,
        FIRST_VALUE(journal_detail_value) OVER window_status AS to_status_id,
        COALESCE(issue_closed_on, v_current_timestamp) AS to_status_date
      FROM issue_journal_statuses
      WINDOW window_status AS ( PARTITION BY issue_id ORDER BY journals_created_on DESC )
    )
  ),
  "excluded_holidays" AS (
    -- Every (calendar, date) pair excluded by a non-matching holiday,
    -- materialized once instead of re-evaluated as a correlated NOT IN
    -- subquery per (day, schedule, status-interval) row below.
    SELECT DISTINCT
      "sla_calendar_holidays"."sla_calendar_id",
      "sla_holidays"."date"
    FROM "sla_holidays"
    INNER JOIN "sla_calendar_holidays"
      ON ( "sla_calendar_holidays"."sla_holiday_id" = "sla_holidays"."id" )
    WHERE NOT "sla_calendar_holidays"."match"
  )
  -- No DISTINCT: this aggregates (SUM, no GROUP BY) down to a single row
  -- regardless, so it was pure overhead forcing a pointless dedup pass over
  -- that one row (see the same cleanup already applied to sla_get_level.sql).
  SELECT
    NULL::integer AS "id",
    COALESCE( v_sla_spent."sla_cache_id", v_sla_cache."id" ) AS "sla_cache_id",
    v_issue_project_id AS "sla_project_id",
    p_issue_id AS "issue_id",
    p_sla_type_id AS "sla_type_id",
    COALESCE(SUM(
      GREATEST(0, EXTRACT(EPOCH FROM (
        LEAST(
          "issue_roll_statuses"."to_status_date",
          -- sla_schedules.end_time is stored as the last valid SECOND of the
          -- last valid minute (e.g. "12:29:59"), not a clean top-of-minute
          -- boundary. +1 second reaches the true exclusive upper bound
          -- ("12:30:00"); +1 minute (the previous bug) overshot by 59s,
          -- inflating the SUM by ~1 minute and rounding up on the final
          -- ::integer cast.
          "calendar"."day_date" + "sla_schedules"."end_time" + INTERVAL '1 second',
          v_issue_closed_on + INTERVAL '1 minute'
        )
        -
        GREATEST(
          "issue_roll_statuses"."from_status_date",
          "calendar"."day_date" + "sla_schedules"."start_time",
          v_issue_created_on
        )
      )) / 60)
    ), 0)::integer AS "spent",
    v_current_timestamp AS "created_on",
    v_current_timestamp AS "updated_on"
  INTO
    v_sla_spent
  FROM
    "issue_roll_statuses"
  INNER JOIN
    ( SELECT generate_series ( DATE_TRUNC('day', v_issue_created_on), DATE_TRUNC('day', v_issue_closed_on), '1 day' ) AS day_date ) AS "calendar"
      ON TRUE
  INNER JOIN
    "sla_schedules"
      ON ( DATE_PART('dow', calendar.day_date) = "sla_schedules"."dow" )
  INNER JOIN
    "sla_calendars"
      ON ( "sla_calendars"."id" = "sla_schedules"."sla_calendar_id" )
  INNER JOIN
    "sla_levels"
      ON ( "sla_levels"."sla_calendar_id" = "sla_calendars"."id" AND "sla_levels"."id" = v_sla_cache.sla_level_id )
  INNER JOIN
    "sla_project_trackers"
      ON ( "sla_project_trackers"."sla_id" = "sla_levels"."sla_id" )
  LEFT JOIN
    "excluded_holidays"
      ON (
        "excluded_holidays"."sla_calendar_id" = "sla_calendars"."id"
        AND "excluded_holidays"."date" = "calendar"."day_date"::date
      )
  WHERE
    "issue_roll_statuses"."from_status_id" IN ( SELECT DISTINCT "sla_statuses"."status_id" FROM "sla_statuses" WHERE "sla_statuses"."sla_type_id" = p_sla_type_id )
  AND
    "sla_project_trackers"."project_id" = v_issue_project_id
  AND
    "sla_project_trackers"."tracker_id" = v_issue_tracker_id
  AND
    -- Exclude dates defined in the holiday calendar (anti-join: no match found above)
    "excluded_holidays"."date" IS NULL
  AND
    -- Only keep (day, schedule, status-interval) triples that actually overlap
    GREATEST(
      "issue_roll_statuses"."from_status_date",
      "calendar"."day_date" + "sla_schedules"."start_time",
      v_issue_created_on
    )
    <
    LEAST(
      "issue_roll_statuses"."to_status_date",
      "calendar"."day_date" + "sla_schedules"."end_time" + INTERVAL '1 minute',
      v_issue_closed_on + INTERVAL '1 minute'
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