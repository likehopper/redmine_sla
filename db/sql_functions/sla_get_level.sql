-- Get level based on issue's project, tracker, created date and time
CREATE OR REPLACE FUNCTION sla_get_level(
    -- From issue, we get the information we need ( project, tracker, created date and time )
    p_issue_id INTEGER    
)
  -- Return cache table record
  RETURNS sla_caches AS
$BODY$
  DECLARE v_issue_project_id INTEGER ;
  DECLARE v_issue_tracker_id INTEGER ;
  DECLARE v_issue_created_on TIMESTAMPTZ ;
  DECLARE v_sla_cache sla_caches ;
BEGIN
  
  RAISE DEBUG
    'sla_get_level	BEGIN ---' ;	

  -- SET SESSION timezone TO 'Etc/UTC';

  -- We avoid looking for a missing issue
  IF ( p_issue_id IS NULL ) THEN
    RETURN NULL ;
  END IF ;

  -- We get the information already in the cache (if it is there, then it is good)
  SELECT
    "sla_caches"."id" AS "id",
    "sla_caches"."issue_id" AS "issue__id",
    "sla_caches"."sla_level_id" AS "sla_level_id",
    "sla_caches"."start_date" AS "start_date"
	INTO
		v_sla_cache
	FROM
		"sla_caches"
	WHERE
		"sla_caches"."issue_id" = p_issue_id
	;         

  -- If the information is there.
  IF ( v_sla_cache IS NOT NULL ) THEN
    -- So we can return it.
    RETURN v_sla_cache ;
  END IF ;

	-- So we take the information we need ( project, tracker, created date and time)
  SELECT
    sla_get_date( "issues"."created_on" ),
    tracker_id,
    project_id
	INTO
		v_issue_created_on,
    v_issue_tracker_id,
    v_issue_project_id 
	FROM
		issues 
	WHERE
		id = p_issue_id
  ;

  RAISE DEBUG
    'sla_get_level	v_issue_created_on = %', v_issue_created_on ;

	-- So we can find the expected level according to the project, tracker, created date and time
  SELECT DISTINCT
    -- Preparing the record for the cache, ID will be determined on insert in the cache
    NULL::bigint AS "id",
    "p_issue_id" AS "issue_id",
		"sla_levels"."id" AS "sla_level_id",
    "calendrier"."minutes" AS "start_date"
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
    RETURN NULL ;
  END IF ;

  -- Insert the data in the level cache
  INSERT INTO "sla_caches" (
    "issue_id",
    "sla_level_id",
    "start_date"
  ) VALUES (
    v_sla_cache."issue_id",
    v_sla_cache."sla_level_id",
    v_sla_cache."start_date"
  ) RETURNING id INTO v_sla_cache."id" ;

  RAISE DEBUG
		'sla_get_level	END ------' ;  	

	RETURN v_sla_cache ;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;