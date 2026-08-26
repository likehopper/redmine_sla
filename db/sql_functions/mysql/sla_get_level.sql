-- File: redmine_sla/db/sql_functions/mysql/sla_get_level.sql
-- MySQL 8.0+ / MariaDB 10.2+ equivalent of the PostgreSQL sla_get_level function.
-- Determine the SLA level for a given issue based on its project, tracker,
-- and creation timestamp. The result is cached in the sla_caches table.
--
-- Unlike the PostgreSQL version, this does not return the cache row: MySQL and
-- MariaDB have no composite/row return type, and stored functions cannot have
-- default parameter values or be overloaded by argument count (unlike
-- PostgreSQL, where p_refresh_force defaults to FALSE). Every Ruby caller
-- already discards the return value and re-reads the persisted sla_caches row
-- afterward (see app/models/sla_cache.rb), so this function only returns the
-- resulting sla_level_id (or NULL) as a convenience for direct SQL callers,
-- and p_refresh_force must always be passed explicitly.
--
-- Requirement: this function writes to sla_caches, so if binary logging is
-- enabled the server needs `log_bin_trust_function_creators = 1` (globally,
-- or at least for the session/user that runs this migration), otherwise
-- CREATE FUNCTION fails with error 1418.
--
-- No DROP FUNCTION / DELIMITER here: this file must be exactly one statement
-- (see sla_get_date.sql for why). The migration issues DROP FUNCTION IF
-- EXISTS separately before executing this file.
CREATE FUNCTION sla_get_level(p_issue_id INT, p_refresh_force BOOLEAN)
RETURNS INT
MODIFIES SQL DATA
NOT DETERMINISTIC
BEGIN
    DECLARE v_issue_project_id INT DEFAULT NULL;
    DECLARE v_issue_tracker_id INT DEFAULT NULL;
    DECLARE v_issue_created_on DATETIME DEFAULT NULL;
    DECLARE v_current_timestamp DATETIME DEFAULT NULL;

    DECLARE v_cache_id BIGINT DEFAULT NULL;
    DECLARE v_cache_sla_level_id INT DEFAULT NULL;
    DECLARE v_cache_created_on DATETIME DEFAULT NULL;

    DECLARE v_result_sla_level_id INT DEFAULT NULL;
    DECLARE v_result_start_date DATETIME DEFAULT NULL;

    -- A SELECT ... INTO that matches zero rows raises a "no data" (SQLSTATE
    -- 02000) condition in MySQL/MariaDB; PostgreSQL's PL/pgSQL simply leaves
    -- the target NULL instead. This single catch-all handler restores that
    -- behaviour for every SELECT ... INTO below.
    DECLARE CONTINUE HANDLER FOR NOT FOUND BEGIN END;

    IF ( p_issue_id IS NULL ) THEN
        RETURN NULL;
    END IF;

    SET v_current_timestamp = sla_get_date(NOW());

    -- Try to retrieve the SLA level already stored in the cache
    SELECT id, sla_level_id, created_on
    INTO v_cache_id, v_cache_sla_level_id, v_cache_created_on
    FROM sla_caches
    WHERE issue_id = p_issue_id;

    -- If a cache exists and refresh is not forced, reuse cache and exit
    IF ( v_cache_id IS NOT NULL AND NOT p_refresh_force ) THEN
        RETURN v_cache_sla_level_id;
    END IF;

    -- Load required issue attributes (project, tracker, creation date)
    SELECT sla_get_date(created_on), tracker_id, project_id
    INTO v_issue_created_on, v_issue_tracker_id, v_issue_project_id
    FROM issues
    WHERE id = p_issue_id;

    -- Compute the expected SLA level.
    -- Generates one row per CALENDAR DAY in the 7-day window starting at
    -- issue creation (not per minute -- see sla_get_spent.sql for the same
    -- rationale), crossed with each candidate schedule, then derives the
    -- exact starting minute for each valid (day, schedule) pair
    -- analytically (GREATEST of issue creation and that window's opening
    -- time) instead of by enumeration. The earliest such minute across all
    -- valid pairs is the SLA start date -- precision is still to the
    -- minute, it's just computed at the boundary of each candidate window
    -- instead of scanned one minute at a time. This needs candidates only
    -- at day granularity (7 days x a handful of schedules) rather than
    -- every one of the ~10,000 minutes in the window; MariaDB's optimizer
    -- in particular badly underestimates the row count of a recursive CTE
    -- producing a minute-by-minute calendar, which cascades into a poor
    -- join plan once that many candidate rows are involved. At 7 rows the
    -- day sequence no longer needs the session recursion-depth cap raised
    -- at all (well under the default 1000-iteration limit either engine
    -- starts with).

    WITH matched_holidays AS (
      -- Every (calendar, date) pair that overrides a normally-excluded
      -- schedule back to matching, materialized once instead of joined
      -- as an inline derived table per candidate day.
      SELECT sla_holidays.`date` AS `date`, sla_calendar_holidays.sla_calendar_id AS sla_calendar_id
      FROM sla_calendar_holidays
      INNER JOIN sla_holidays
        ON (
          sla_holidays.id = sla_calendar_holidays.sla_holiday_id
          AND sla_calendar_holidays.`match`
        )
    ),
    excluded_holidays AS (
      -- Every (calendar, date) pair excluded by a non-matching holiday,
      -- same rationale as matched_holidays above.
      SELECT DISTINCT sla_calendar_holidays.sla_calendar_id AS sla_calendar_id, sla_holidays.`date` AS `date`
      FROM sla_holidays
      INNER JOIN sla_calendar_holidays
        ON (sla_holidays.id = sla_calendar_holidays.sla_holiday_id)
      WHERE NOT sla_calendar_holidays.`match`
    )
    SELECT sla_levels.id, GREATEST(v_issue_created_on, TIMESTAMP(calendar.day_date, sla_schedules.start_time))
    INTO v_result_sla_level_id, v_result_start_date
    FROM
      (
        WITH RECURSIVE seq AS (
          SELECT 0 AS n
          UNION ALL
          SELECT n + 1 FROM seq WHERE n < 7
        )
        SELECT DATE_ADD(DATE(v_issue_created_on), INTERVAL n DAY) AS day_date
        FROM seq
      ) AS calendar
      INNER JOIN sla_schedules
        ON (
          -- PostgreSQL DATE_PART('dow', ...) is 0=Sunday..6=Saturday.
          -- MySQL DAYOFWEEK() is 1=Sunday..7=Saturday, hence the "- 1".
          (DAYOFWEEK(calendar.day_date) - 1) = sla_schedules.dow
        )
      INNER JOIN sla_calendars
        ON (sla_calendars.id = sla_schedules.sla_calendar_id)
      INNER JOIN sla_levels
        ON (sla_levels.sla_calendar_id = sla_calendars.id)
      INNER JOIN sla_project_trackers
        ON (sla_project_trackers.sla_id = sla_levels.sla_id)
      LEFT JOIN matched_holidays
        ON (
          matched_holidays.sla_calendar_id = sla_schedules.sla_calendar_id
          AND matched_holidays.`date` = calendar.day_date
        )
      LEFT JOIN excluded_holidays
        ON (
          excluded_holidays.sla_calendar_id = sla_calendars.id
          AND excluded_holidays.`date` = calendar.day_date
        )
    WHERE
      -- Must match project and tracker SLA configuration
      sla_project_trackers.project_id = v_issue_project_id
      AND sla_project_trackers.tracker_id = v_issue_tracker_id

      -- Exclude declared "non-matching" holidays (anti-join: no match found above)
      AND excluded_holidays.`date` IS NULL

      -- Validate either schedule match OR holiday override
      AND (
        sla_schedules.`match`
        OR matched_holidays.`date` = calendar.day_date
      )

      -- Skip windows that had already closed before the issue was even
      -- created (only possible on the creation day itself: every later
      -- day's window necessarily opens after issue creation).
      AND TIMESTAMP(calendar.day_date, sla_schedules.end_time) >= v_issue_created_on

      -- Trim back to the exact 7-day-from-creation bound: generating whole
      -- calendar days above can otherwise pull in one day too many.
      AND GREATEST(v_issue_created_on, TIMESTAMP(calendar.day_date, sla_schedules.start_time)) <= DATE_ADD(v_issue_created_on, INTERVAL 7 DAY)

    ORDER BY GREATEST(v_issue_created_on, TIMESTAMP(calendar.day_date, sla_schedules.start_time))
    LIMIT 1;

    -- No matching SLA level found within search window → clear cache + return NULL
    IF ( v_result_sla_level_id IS NULL ) THEN
        DELETE FROM sla_caches WHERE issue_id = p_issue_id;
        RETURN NULL;
    END IF;

    -- Insert or update the SLA cache entry
    INSERT INTO sla_caches (
      id, project_id, issue_id, tracker_id, sla_level_id, start_date, created_on, updated_on
    ) VALUES (
      p_issue_id, v_issue_project_id, p_issue_id, v_issue_tracker_id,
      v_result_sla_level_id, v_result_start_date,
      COALESCE(v_cache_created_on, v_current_timestamp), v_current_timestamp
    )
    ON DUPLICATE KEY UPDATE
      project_id = VALUES(project_id),
      tracker_id = VALUES(tracker_id),
      sla_level_id = VALUES(sla_level_id),
      start_date = VALUES(start_date),
      updated_on = VALUES(updated_on);

    RETURN v_result_sla_level_id;
END
