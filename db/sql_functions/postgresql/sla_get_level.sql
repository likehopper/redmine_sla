-- File: redmine_sla/db/sql_functions/sla_get_level.sql 
-- Determine the SLA level for a given issue based on its project, tracker,
-- and creation timestamp. The result is cached in the sla_caches table.

CREATE OR REPLACE FUNCTION sla_get_level(
    -- Issue identifier from which all SLA-related attributes are derived
    p_issue_id INTEGER,

    -- Force recalculation even if a cache entry already exists
    p_refresh_force BOOLEAN DEFAULT FALSE   
)
  -- Function returns a record of type sla_caches (SLA cache entry)
  RETURNS sla_caches AS
$BODY$
  ---------------------------------------------------------------------------
  -- Variable declarations
  ---------------------------------------------------------------------------
  DECLARE v_issue_project_id INTEGER ;
  DECLARE v_issue_tracker_id INTEGER ;
  DECLARE v_issue_created_on TIMESTAMP WITHOUT TIME ZONE ;
  -- DECLARE v_issue_updated_on TIMESTAMP WITHOUT TIME ZONE ;  -- (unused)
  DECLARE v_current_timestamp TIMESTAMP WITHOUT TIME ZONE ;
  DECLARE v_sla_cache sla_caches ;

BEGIN

  RAISE DEBUG 'sla_get_level | BEGIN ---' ;

  ---------------------------------------------------------------------------
  -- Safety check: issue ID must be provided
  ---------------------------------------------------------------------------
  IF ( p_issue_id IS NULL ) THEN
    RAISE DEBUG 'sla_get_level | p_issue_id IS NULL' ;
    RETURN NULL ;
  END IF ;

  RAISE DEBUG 'sla_get_level | p_issue_id = %', p_issue_id ;

  ---------------------------------------------------------------------------
  -- Evaluate the current normalized timestamp using SLA calendar settings
  ---------------------------------------------------------------------------
  v_current_timestamp := sla_get_date(NOW()::TIMESTAMP WITHOUT TIME ZONE);
  RAISE DEBUG 'sla_get_level | v_current_timestamp = %', v_current_timestamp ;

  ---------------------------------------------------------------------------
  -- Try to retrieve the SLA level already stored in the cache
  ---------------------------------------------------------------------------
  SELECT
    "sla_caches"."id" AS "id",
    "sla_caches"."project_id" AS "project_id",
    "sla_caches"."issue_id" AS "issue_id",
    "sla_caches"."tracker_id" AS "tracker_id",
    "sla_caches"."sla_level_id" AS "sla_level_id",
    "sla_caches"."start_date" AS "start_date",
    "sla_caches"."created_on" AS "created_on",
    "sla_caches"."updated_on" AS "updated_on"
  INTO v_sla_cache
  FROM "sla_caches"
  WHERE "sla_caches"."issue_id" = p_issue_id ;

  RAISE DEBUG 'sla_get_level | v_sla_spent.sla_level_id = %', v_sla_cache."sla_level_id" ;

  ---------------------------------------------------------------------------
  -- If a cache exists and refresh is not forced, reuse cache and exit
  ---------------------------------------------------------------------------
  IF ( ( v_sla_cache IS NOT NULL ) AND ( NOT p_refresh_force ) ) THEN
    RAISE DEBUG 'sla_get_level | RETURN cached result (no refresh requested)' ;
    RETURN v_sla_cache ;
  END IF ;

  RAISE DEBUG 'sla_get_level | v_sla_spent.updated_on = %', v_sla_cache."updated_on" ;

  ---------------------------------------------------------------------------
  -- Load required issue attributes (project, tracker, creation date)
  ---------------------------------------------------------------------------
  SELECT
    sla_get_date("issues"."created_on"),
    "issues"."tracker_id",
    "issues"."project_id"
  INTO
    v_issue_created_on,
    -- v_issue_updated_on,
    v_issue_tracker_id,
    v_issue_project_id
  FROM "issues"
  WHERE "issues"."id" = p_issue_id ;

  RAISE DEBUG 'sla_get_level | v_issue_created_on = %', v_issue_created_on ;
  RAISE DEBUG 'sla_get_level | v_issue_project_id = %', v_issue_project_id ;
  RAISE DEBUG 'sla_get_level | v_issue_tracker_id = %', v_issue_tracker_id ;

  ---------------------------------------------------------------------------
  -- Compute the expected SLA level.
  -- This generates every minute within a 7-day window starting at issue creation,
  -- then matches each timestamp against SLA calendars, schedules, holidays,
  -- and project-tracker SLA configuration, to find the first valid SLA start date.
  ---------------------------------------------------------------------------
  WITH "excluded_holidays" AS (
    -- Every (calendar, date) pair excluded by a non-matching holiday.
    -- Materialized once up front instead of re-evaluated as a correlated
    -- subquery per candidate minute (see the anti-join below): with 7 days
    -- of minute granularity there are ~10,000 candidate rows, and a
    -- correlated NOT IN forced a full per-row re-scan of sla_holidays for
    -- each of them -- the dominant cost of this query. A single
    -- pre-computed set turns that into one ordinary hash join.
    SELECT DISTINCT
      "sla_calendar_holidays"."sla_calendar_id",
      "sla_holidays"."date"
    FROM "sla_holidays"
    INNER JOIN "sla_calendar_holidays"
      ON ( "sla_holidays"."id" = "sla_calendar_holidays"."sla_holiday_id" )
    WHERE NOT "sla_calendar_holidays"."match"
  ),
  "matched_holidays" AS (
    -- Every (calendar, date) pair that overrides a normally-excluded
    -- schedule back to matching. Same rationale as excluded_holidays right
    -- above: this was previously an inline derived table LEFT JOINed
    -- straight into the calendar, which the planner evaluated as a
    -- per-row indexed nested loop (one sla_holidays lookup per one of the
    -- ~10,000 candidate minutes) instead of hashing it once like its
    -- excluded_holidays sibling.
    SELECT DISTINCT
      "sla_calendar_holidays"."sla_calendar_id",
      "sla_holidays"."date"
    FROM "sla_calendar_holidays"
    INNER JOIN "sla_holidays"
      ON (
        "sla_holidays"."id" = "sla_calendar_holidays"."sla_holiday_id"
        AND "sla_calendar_holidays"."match"
      )
  )
  -- No DISTINCT: LIMIT 1 already caps the result to a single row regardless,
  -- and the MySQL port of this same query (already validated end-to-end
  -- against the real test suite) never needed one either -- it was pure
  -- overhead forcing a full dedup pass before the LIMIT could apply.
  SELECT
    -- Cache record to be written (cache ID is determined at INSERT time)
    NULL::bigint AS "id",
    "v_issue_project_id" AS "project_id",
    "p_issue_id" AS "issue_id",
    "v_issue_tracker_id" AS "tracker_id",
    "sla_levels"."id" AS "sla_level_id",

    -- First matching SLA calendar minute becomes the SLA start date
    "calendar"."minutes" AS "start_date",

    -- Keep original creation date from cache if available
    COALESCE(v_sla_cache.created_on, v_current_timestamp) AS "created_on",

    -- Always refresh updated_on
    v_current_timestamp AS "updated_on"
  INTO v_sla_cache
  FROM (
    -- Generate a minute-by-minute calendar for the next 7 days
    SELECT generate_series(
      v_issue_created_on,
      v_issue_created_on + INTERVAL '7 days',
      '1 minute'
    ) AS minutes
  ) AS "calendar"

  INNER JOIN "sla_schedules"
    ON (
      DATE_PART('dow',"calendar"."minutes") = "sla_schedules"."dow"
      AND "calendar"."minutes"::TIME BETWEEN "sla_schedules"."start_time"
                                           AND "sla_schedules"."end_time"
    )

  INNER JOIN "sla_calendars"
    ON ( "sla_calendars"."id" = "sla_schedules"."sla_calendar_id" )

  INNER JOIN "sla_levels"
    ON ( "sla_levels"."sla_calendar_id" = "sla_calendars"."id" )

  INNER JOIN "sla_project_trackers"
    ON ( "sla_project_trackers"."sla_id" = "sla_levels"."sla_id" )

  LEFT JOIN "matched_holidays"
    ON (
      "matched_holidays"."sla_calendar_id" = "sla_schedules"."sla_calendar_id"
      AND "matched_holidays"."date" = "calendar"."minutes"::DATE
    )

  LEFT JOIN "excluded_holidays"
    ON (
      "excluded_holidays"."sla_calendar_id" = "sla_calendars"."id"
      AND "excluded_holidays"."date" = "calendar"."minutes"::DATE
    )

  WHERE
    -- Must match project and tracker SLA configuration
    "sla_project_trackers"."project_id" = v_issue_project_id
    AND "sla_project_trackers"."tracker_id" = v_issue_tracker_id

    -- Exclude declared "non-matching" holidays (anti-join: no match found above)
    AND "excluded_holidays"."date" IS NULL

    -- Validate either schedule match OR holiday override
    AND (
      "sla_schedules"."match"
      OR "matched_holidays"."date" = "calendar"."minutes"::DATE
    )

  ORDER BY "calendar"."minutes"
  LIMIT 1 ;

  ---------------------------------------------------------------------------
  -- No matching SLA level found within search window → clear cache + return NULL
  ---------------------------------------------------------------------------
  IF ( v_sla_cache IS NULL ) THEN
    RAISE DEBUG 'sla_get_level | No valid SLA level found → return NULL' ;

    DELETE FROM "sla_caches"
    WHERE "sla_caches"."issue_id" = p_issue_id ;

    RETURN NULL ;
  END IF ;

  ---------------------------------------------------------------------------
  -- Insert or update the SLA cache entry
  ---------------------------------------------------------------------------
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

  -- If entry already exists, update fields instead of inserting
  ON CONFLICT ON CONSTRAINT "sla_caches_issues_ukey"
  DO UPDATE SET
    "project_id"  = v_sla_cache."project_id",
    "tracker_id"  = v_sla_cache."tracker_id",
    "sla_level_id" = v_sla_cache."sla_level_id",
    "start_date"   = v_sla_cache."start_date",
    "updated_on"   = v_sla_cache."updated_on"
  RETURNING id INTO v_sla_cache."id" ;

  RAISE DEBUG 'sla_get_level | END ------' ;

  RETURN v_sla_cache ;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;