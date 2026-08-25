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
    -- This generates every minute within a 7-day window starting at issue creation,
    -- then matches each timestamp against SLA calendars, schedules, holidays,
    -- and project-tracker SLA configuration, to find the first valid SLA start date.
    -- MySQL/MariaDB have no generate_series: a bounded recursive CTE stands
    -- in for it. Two earlier approaches were tried and dropped:
    --   - a digit cross join computed inline (correct, but ~15-20x slower per
    --     call: MySQL materializes a fresh 5-way UNION ALL cross join of
    --     20,000 rows every time instead of a cheap range).
    --   - a persisted, indexed sla_mysql_numbers sequence table populated by
    --     a migration (fast, but its *data* -- unlike the schema -- is not
    --     captured by `rails db:schema:load` from db/structure.sql, which is
    --     how Rails normally builds a test database; every stored function
    --     depending on it silently returned NULL there even though it worked
    --     fine on a directly-migrated database).
    -- A recursive CTE avoids both problems and needs no persisted state; the
    -- session recursion-depth cap only needs raising because the 7-day
    -- window is bigger than MySQL's default limit of 1000.
    SET SESSION cte_max_recursion_depth = 10180;

    SELECT sla_levels.id, calendar.minutes
    INTO v_result_sla_level_id, v_result_start_date
    FROM
      (
        WITH RECURSIVE seq AS (
          SELECT 0 AS n
          UNION ALL
          SELECT n + 1 FROM seq WHERE n < 10080
        )
        SELECT DATE_ADD(v_issue_created_on, INTERVAL n MINUTE) AS minutes
        FROM seq
      ) AS calendar
      INNER JOIN sla_schedules
        ON (
          -- PostgreSQL DATE_PART('dow', ...) is 0=Sunday..6=Saturday.
          -- MySQL DAYOFWEEK() is 1=Sunday..7=Saturday, hence the "- 1".
          (DAYOFWEEK(calendar.minutes) - 1) = sla_schedules.dow
          AND TIME(calendar.minutes) BETWEEN sla_schedules.start_time AND sla_schedules.end_time
        )
      INNER JOIN sla_calendars
        ON (sla_calendars.id = sla_schedules.sla_calendar_id)
      INNER JOIN sla_levels
        ON (sla_levels.sla_calendar_id = sla_calendars.id)
      INNER JOIN sla_project_trackers
        ON (sla_project_trackers.sla_id = sla_levels.sla_id)
      LEFT JOIN
        (
          -- Fetch holidays that override schedule match behaviour
          SELECT sla_holidays.`date` AS `date`, sla_calendar_holidays.sla_calendar_id AS sla_calendar_id
          FROM sla_calendar_holidays
          INNER JOIN sla_holidays
            ON (
              sla_holidays.id = sla_calendar_holidays.sla_holiday_id
              AND sla_calendar_holidays.`match`
            )
        ) AS sla_holiday_match
        ON (
          sla_holiday_match.sla_calendar_id = sla_schedules.sla_calendar_id
          AND sla_holiday_match.`date` = DATE(calendar.minutes)
        )
    WHERE
      -- Must match project and tracker SLA configuration
      sla_project_trackers.project_id = v_issue_project_id
      AND sla_project_trackers.tracker_id = v_issue_tracker_id

      -- Exclude declared "non-matching" holidays
      AND DATE(calendar.minutes) NOT IN (
        SELECT sla_holidays.`date`
        FROM sla_holidays
        INNER JOIN sla_calendar_holidays
          ON (sla_holidays.id = sla_calendar_holidays.sla_holiday_id)
        WHERE
          sla_calendar_holidays.sla_calendar_id = sla_calendars.id
          AND NOT sla_calendar_holidays.`match`
      )

      -- Validate either schedule match OR holiday override
      AND (
        sla_schedules.`match`
        OR sla_holiday_match.`date` = DATE(calendar.minutes)
      )

    ORDER BY calendar.minutes
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
