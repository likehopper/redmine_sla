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
  -- Generates one row per CALENDAR DAY in the 7-day window starting at issue
  -- creation (not per minute -- see sla_get_spent.sql for the same
  -- rationale), crossed with each candidate schedule, then derives the
  -- exact starting minute for each valid (day, schedule) pair analytically
  -- (GREATEST of issue creation and that window's opening time) instead of
  -- by enumeration. The earliest such minute across all valid pairs is the
  -- SLA start date -- precision is still to the minute, it's just computed
  -- at the boundary of each candidate window instead of scanned one minute
  -- at a time. This needs candidates only at day granularity (~7 days x a
  -- handful of schedules) rather than every one of the ~10,000 minutes in
  -- the window; MariaDB's optimizer in particular badly underestimates the
  -- row count of the recursive CTE producing a minute-by-minute calendar,
  -- which cascades into a poor join plan once that many candidate rows are
  -- involved.
  ---------------------------------------------------------------------------
  WITH "excluded_holidays" AS (
    -- Every (calendar, date) pair excluded by a non-matching holiday.
    -- Materialized once up front instead of re-evaluated as a correlated
    -- subquery per candidate day.
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
    -- schedule back to matching. Same rationale as excluded_holidays.
    SELECT DISTINCT
      "sla_calendar_holidays"."sla_calendar_id",
      "sla_holidays"."date"
    FROM "sla_calendar_holidays"
    INNER JOIN "sla_holidays"
      ON (
        "sla_holidays"."id" = "sla_calendar_holidays"."sla_holiday_id"
        AND "sla_calendar_holidays"."match"
      )
  ),
  "calendar" AS (
    -- One row per CALENDAR DAY covering the 7-day search window (truncated
    -- to day boundaries, so this can include up to one extra day on each
    -- end versus the exact instant range -- the WHERE clause below trims
    -- candidates back to the precise [issue creation, +7 days] bound).
    SELECT generate_series(
      DATE_TRUNC('day', v_issue_created_on),
      DATE_TRUNC('day', v_issue_created_on) + INTERVAL '7 days',
      '1 day'
    ) AS day_date
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

    -- Exact starting minute for this (day, schedule) pair: either the
    -- issue's own creation instant, if it already falls inside this
    -- window, or the window's opening time that day.
    GREATEST(v_issue_created_on, "calendar"."day_date" + "sla_schedules"."start_time") AS "start_date",

    -- Keep original creation date from cache if available
    COALESCE(v_sla_cache.created_on, v_current_timestamp) AS "created_on",

    -- Always refresh updated_on
    v_current_timestamp AS "updated_on"
  INTO v_sla_cache
  FROM "calendar"

  INNER JOIN "sla_schedules"
    ON ( DATE_PART('dow',"calendar"."day_date") = "sla_schedules"."dow" )

  INNER JOIN "sla_calendars"
    ON ( "sla_calendars"."id" = "sla_schedules"."sla_calendar_id" )

  INNER JOIN "sla_levels"
    ON ( "sla_levels"."sla_calendar_id" = "sla_calendars"."id" )

  INNER JOIN "sla_project_trackers"
    ON ( "sla_project_trackers"."sla_id" = "sla_levels"."sla_id" )

  LEFT JOIN "matched_holidays"
    ON (
      "matched_holidays"."sla_calendar_id" = "sla_schedules"."sla_calendar_id"
      AND "matched_holidays"."date" = "calendar"."day_date"::DATE
    )

  LEFT JOIN "excluded_holidays"
    ON (
      "excluded_holidays"."sla_calendar_id" = "sla_calendars"."id"
      AND "excluded_holidays"."date" = "calendar"."day_date"::DATE
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
      OR "matched_holidays"."date" = "calendar"."day_date"::DATE
    )

    -- Skip windows that had already closed before the issue was even
    -- created (only possible on the creation day itself: every later
    -- day's window necessarily opens after issue creation).
    AND "calendar"."day_date" + "sla_schedules"."end_time" >= v_issue_created_on

    -- Trim back to the exact 7-day-from-creation bound: generating whole
    -- calendar days above can otherwise pull in one day too many.
    AND GREATEST(v_issue_created_on, "calendar"."day_date" + "sla_schedules"."start_time") <= v_issue_created_on + INTERVAL '7 days'

  ORDER BY GREATEST(v_issue_created_on, "calendar"."day_date" + "sla_schedules"."start_time")
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