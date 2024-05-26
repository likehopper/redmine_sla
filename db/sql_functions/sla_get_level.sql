-- Get level based on issue's project, tracker, created date and time
CREATE OR REPLACE FUNCTION sla_get_level(
    -- From issue, we get the information we need ( project, tracker, created date and time )
    p_issue_id INTEGER,
    p_refresh_force BOOLEAN DEFAULT FALSE   
)
  -- Return cache table record
  RETURNS sla_caches AS
$BODY$
  DECLARE v_issue_project_id INTEGER ;
  DECLARE v_issue_tracker_id INTEGER ;
  DECLARE v_issue_created_on TIMESTAMP WITHOUT TIME ZONE ;
  -- DECLARE v_issue_updated_on TIMESTAMP WITHOUT TIME ZONE ;
  DECLARE v_current_timestamp TIMESTAMP WITHOUT TIME ZONE ;
  DECLARE v_sla_cache sla_caches ;
BEGIN
  
  RAISE DEBUG 'sla_get_level | BEGIN ---' ;	

  -- We avoid looking for a missing issue
  IF ( p_issue_id IS NULL ) THEN
    RAISE DEBUG 'sla_get_level | p_issue_id IS NULL' ;
    RETURN NULL ;
  END IF ;

  RAISE DEBUG 'sla_get_level | p_issue_id = %', p_issue_id ; 

  -- We get the date and time from now
  v_current_timestamp := sla_get_date(NOW()::TIMESTAMP WITHOUT TIME ZONE);

  RAISE DEBUG 'sla_get_level | v_current_timestamp = %', v_current_timestamp ;

  -- We get the information already in the cache (if it is there, then it is good)
  SELECT
    "sla_caches"."id" AS "id",
    "sla_caches"."project_id" AS "project_id",
    "sla_caches"."issue_id" AS "issue_id",
    "sla_caches"."tracker_id" AS "tracker_id",
    "sla_caches"."sla_level_id" AS "sla_level_id",
    "sla_caches"."start_date" AS "start_date",
    "sla_caches"."created_on" AS "created_on",
    "sla_caches"."updated_on" AS "updated_on"
	INTO
		v_sla_cache
	FROM
		"sla_caches"
	WHERE
		"sla_caches"."issue_id" = p_issue_id
	; 

  RAISE DEBUG 'sla_get_level | v_sla_spent.sla_level_id = %', v_sla_cache."sla_level_id" ;

  -- If the information is there and no need to force refresh
  IF ( ( v_sla_cache IS NOT NULL ) AND ( NOT p_refresh_force ) ) THEN
    RAISE DEBUG 'sla_get_level | RETURN v_sla_cache IS NOT NULL AND NOT p_refresh_force ------' ;
    -- So we can return it.
    RETURN v_sla_cache ;
  END IF ;

  RAISE DEBUG 'sla_get_level | v_sla_spent.updated_on = %', v_sla_cache."updated_on" ;

  -- So we take the information we need ( project, tracker, created date and time)
  SELECT
    sla_get_date( "issues"."created_on" ),
    "issues"."tracker_id",
    "issues"."project_id"
  INTO
    v_issue_created_on,
    -- v_issue_updated_on,
    v_issue_tracker_id,
    v_issue_project_id
  FROM
    "issues"
  WHERE
    "issues"."id" = p_issue_id
  ;

  RAISE DEBUG 'sla_get_level | v_issue_created_on = %', v_issue_created_on ;
  RAISE DEBUG 'sla_get_level | v_issue_project_id = %', v_issue_project_id ;
  RAISE DEBUG 'sla_get_level | v_issue_tracker_id = %', v_issue_tracker_id ;

	-- So we can find the expected level according to the project, tracker, created date and time
  SELECT DISTINCT
    -- Preparing the record for the cache, ID will be determined on insert in the cache
    NULL::bigint AS "id",
    "v_issue_project_id" AS "project_id",
    "p_issue_id" AS "issue_id",
    "v_issue_tracker_id" AS "tracker_id",
		"sla_levels"."id" AS "sla_level_id",
    "calendrier"."minutes" AS "start_date",
    COALESCE(v_sla_cache.created_on,v_current_timestamp) AS "created_on",
    v_current_timestamp AS "updated_on"
	INTO
		v_sla_cache
  FROM            
    ( SELECT generate_series( v_issue_created_on, v_issue_created_on + INTERVAL '7 days', '1 minute') AS minutes ) AS "calendrier"
  INNER JOIN
    "sla_schedules"
      ON ( DATE_PART('dow',"calendrier"."minutes") = "sla_schedules"."dow" AND "calendrier"."minutes"::TIME BETWEEN "sla_schedules"."start_time" AND "sla_schedules"."end_time" )
  INNER JOIN
    "sla_calendars"
      ON ( "sla_calendars"."id" = "sla_schedules"."sla_calendar_id" )
  INNER JOIN
    "sla_levels"
      ON ( "sla_levels"."sla_calendar_id" = "sla_calendars"."id" )
  INNER JOIN
    "sla_project_trackers"
      ON ( "sla_project_trackers"."sla_id" = "sla_levels"."sla_id" )
  LEFT JOIN
    ( 
      SELECT "date", "sla_calendar_id" 
      FROM "sla_calendar_holidays"
      INNER JOIN "sla_holidays"
          ON ( "sla_holidays"."id" = "sla_calendar_holidays"."sla_holiday_id" AND "sla_calendar_holidays"."match" )
    ) AS "sla_holiday_match"
      ON ( "sla_holiday_match"."sla_calendar_id" = "sla_schedules"."sla_calendar_id" AND "sla_holiday_match"."date" = "calendrier"."minutes"::DATE )
	WHERE
		"sla_project_trackers"."project_id" = v_issue_project_id
	AND
		"sla_project_trackers"."tracker_id" = v_issue_tracker_id
  AND
		"calendrier"."minutes"::DATE NOT IN (
			SELECT "sla_holidays"."date"
			FROM "sla_holidays"
			INNER JOIN "sla_calendar_holidays"
			  ON ( "sla_holidays"."id" = "sla_calendar_holidays"."sla_holiday_id" )
			WHERE "sla_calendar_holidays"."sla_calendar_id" = "sla_calendars"."id"
			AND NOT "sla_calendar_holidays"."match"
	)
  AND 
		( "sla_schedules"."match" OR "sla_holiday_match"."date" = "calendrier"."minutes"::DATE )
	ORDER BY
        	"calendrier"."minutes"
	LIMIT 1 ;

  -- We didn't find anything !
  IF ( v_sla_cache IS NULL ) THEN
    RAISE DEBUG 'sla_get_level | RETURN v_sla_cache IS NULL' ;
    -- We make sure we don't have anything left in case we have something else!
    DELETE FROM "sla_caches" WHERE "sla_caches"."issue_id" = p_issue_id ;  
    RETURN NULL ;
  END IF ;

  -- Insert the data in the level cache
  INSERT INTO "sla_caches" (
    "id",
    "project_id",
    "issue_id",
    "tracker_id",
    "sla_level_id",
    "start_date",
    "created_on",
    "updated_on"
  ) VALUES (
    v_sla_cache."issue_id",
    v_sla_cache."project_id", 
    v_sla_cache."issue_id",
    v_sla_cache."tracker_id",
    v_sla_cache."sla_level_id",
    v_sla_cache."start_date",
    v_sla_cache."created_on",
    v_sla_cache."updated_on"
  )
  -- if data already exists, then do an update
	ON CONFLICT ON CONSTRAINT "sla_caches_issues_ukey" DO UPDATE SET
    "project_id" = v_sla_cache."project_id",
    "tracker_id" = v_sla_cache."tracker_id",
    "sla_level_id" = v_sla_cache."sla_level_id",
    "start_date" = v_sla_cache."start_date",
    "updated_on" = v_sla_cache."updated_on"
  RETURNING id INTO v_sla_cache."id" ;

  RAISE DEBUG 'sla_get_level | END ------' ;  	

	RETURN v_sla_cache ;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;