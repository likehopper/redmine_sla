-- File: redmine_sla/db/sql_functions/mysql/sla_get_spent.sql
-- MySQL 8.0+ / MariaDB 10.2+ equivalent of the PostgreSQL sla_get_spent function.
-- Calculate the total elapsed business minutes for a specific issue and SLA type.
--
-- Like sla_get_level.sql: no composite return type (Ruby callers discard the
-- return value and re-read sla_cache_spents afterward, see
-- app/models/sla_cache_spent.rb), so this returns a scalar (the newly
-- computed delta of spent minutes, matching what the PostgreSQL version
-- actually returns -- see the comment above the final RETURN below).
--
-- Requirement: writes to sla_cache_spents, so if binary logging is enabled
-- the server needs `log_bin_trust_function_creators = 1` (see sla_get_level.sql).
--
-- Note: unlike sla_get_level, this faithfully reproduces the PostgreSQL
-- version's behaviour of NOT filtering on sla_schedules.match or applying the
-- holiday-override branch here -- only match=FALSE holiday dates are
-- excluded. That asymmetry with sla_get_level already exists in the
-- PostgreSQL original; it is preserved as-is rather than "fixed" as part of
-- this port.
--
-- No DROP FUNCTION / DELIMITER here: this file must be exactly one statement
-- (see sla_get_date.sql for why). The migration issues DROP FUNCTION IF
-- EXISTS separately before executing this file.
CREATE FUNCTION sla_get_spent(p_issue_id INT, p_sla_type_id INT)
RETURNS INT
MODIFIES SQL DATA
NOT DETERMINISTIC
BEGIN
    DECLARE v_issue_project_id INT DEFAULT NULL;
    DECLARE v_issue_tracker_id INT DEFAULT NULL;
    DECLARE v_window_start DATETIME DEFAULT NULL;
    DECLARE v_window_end DATETIME DEFAULT NULL;
    DECLARE v_current_timestamp DATETIME DEFAULT NULL;
    DECLARE v_window_days BIGINT DEFAULT NULL;

    DECLARE v_cache_id BIGINT DEFAULT NULL;
    DECLARE v_cache_sla_level_id INT DEFAULT NULL;
    DECLARE v_cache_start_date DATETIME DEFAULT NULL;

    DECLARE v_term_id BIGINT DEFAULT NULL;

    DECLARE v_spent_id INT DEFAULT NULL;
    DECLARE v_spent_updated_on DATETIME DEFAULT NULL;
    DECLARE v_spent_existing INT DEFAULT NULL;

    DECLARE v_new_spent INT DEFAULT 0;

    -- A SELECT ... INTO that matches zero rows raises a "no data" (SQLSTATE
    -- 02000) condition in MySQL/MariaDB; PostgreSQL's PL/pgSQL simply leaves
    -- the target NULL instead. This single catch-all handler restores that
    -- behaviour for every SELECT ... INTO below.
    DECLARE CONTINUE HANDLER FOR NOT FOUND BEGIN END;

    IF ( p_issue_id IS NULL OR p_sla_type_id IS NULL ) THEN
        RETURN NULL;
    END IF;

    SET v_current_timestamp = sla_get_date(NOW());

    -- Identify the current SLA level applied to this issue: call sla_get_level
    -- for its cache-refreshing side effect, then read the cache back (see
    -- sla_get_level.sql for why this can't just use its return value).
    DO sla_get_level(p_issue_id, FALSE);

    SELECT id, sla_level_id, start_date
    INTO v_cache_id, v_cache_sla_level_id, v_cache_start_date
    FROM sla_caches
    WHERE issue_id = p_issue_id;

    -- Exit if the issue is not governed by any SLA level
    IF ( v_cache_id IS NULL ) THEN
        RETURN NULL;
    END IF;

    -- Retrieve the specific terms (thresholds/rules) for this SLA type and level
    SELECT id
    INTO v_term_id
    FROM sla_level_terms
    WHERE sla_level_id = v_cache_sla_level_id
      AND sla_type_id = p_sla_type_id
    LIMIT 1;

    -- Abort if no calculation rules are defined for this specific SLA type
    IF ( v_term_id IS NULL ) THEN
        RETURN NULL;
    END IF;

    -- Check if a spent time record already exists in the cache for this issue and SLA type
    SELECT id, updated_on, spent
    INTO v_spent_id, v_spent_updated_on, v_spent_existing
    FROM sla_cache_spents
    WHERE sla_cache_id = v_cache_id
      AND sla_type_id = p_sla_type_id;

    -- Optimization: If the cache was already updated during this transaction/timestamp, skip recalculation
    IF ( v_spent_id IS NOT NULL AND v_spent_updated_on = v_current_timestamp ) THEN
        RETURN v_spent_existing;
    END IF;

    -- Determine the calculation window: from the last cache update (or SLA start) to the closing date (or now)
    SELECT
      COALESCE(v_spent_updated_on, v_cache_start_date),
      COALESCE(sla_get_date(closed_on), v_current_timestamp),
      tracker_id,
      project_id
    INTO
      v_window_start, v_window_end, v_issue_tracker_id, v_issue_project_id
    FROM issues
    WHERE id = p_issue_id;

    -- Prevent redundant updates if the cache is already newer than the issue's closing date
    IF ( v_spent_updated_on IS NOT NULL AND v_spent_updated_on > v_window_end ) THEN
        UPDATE sla_cache_spents
        SET updated_on = v_current_timestamp
        WHERE sla_cache_id = v_cache_id AND sla_type_id = p_sla_type_id;
        RETURN v_spent_existing;
    END IF;

    SET v_window_days = DATEDIFF(DATE(v_window_end), DATE(v_window_start));

    -- Sanity ceiling to stop a corrupt/absurd window (e.g. a bad closed_on)
    -- from raising the session's recursion depth to something unreasonable.
    -- 100,000 days is ~274 years -- far beyond any real issue lifetime.
    IF ( v_window_days > 100000 ) THEN
        -- MESSAGE_TEXT is capped at 128 characters by MySQL/MariaDB.
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'sla_get_spent: calculation window exceeds 100000 days, check the issue''s dates';
    END IF;

    -- The recursive CTE below needs its bound raised past MySQL's default
    -- session recursion-depth limit of 1000 whenever the window is longer
    -- than that many days.
    SET SESSION cte_max_recursion_depth = v_window_days + 100;

    -- CORE CALCULATION:
    -- 1. Take every CALENDAR DAY in the calculation window from a bounded
    --    recursive CTE (reused here as a day offset rather than a minute
    --    offset -- MySQL/MariaDB have no generate_series). A persisted
    --    sequence table was tried first, populated once by a migration, but
    --    its *data* -- unlike its schema -- is not captured by `rails
    --    db:schema:load` from db/structure.sql, which is how Rails normally
    --    builds a test database; the table came back empty there even
    --    though it worked fine on a directly-migrated database, and every
    --    function depending on it silently returned NULL. A recursive CTE
    --    avoids that problem entirely and needs no persisted state.
    --    Enumerating by day instead of by minute matters a lot here: a status
    --    interval can span years, so a per-minute row count (millions of
    --    rows for an old issue) is far more expensive than summing a
    --    closed-form per-day intersection length (hundreds of rows at most),
    --    for the exact same total.
    -- 2. For each day, intersect that day's business-hours window (schedules)
    --    with the issue's status-history intervals (roll_statuses) and the
    --    calculation window itself, and sum the resulting minute counts.
    -- 3. Exclude public holidays.
    --
    -- issue_roll_statuses below recomputes sla_view_roll_statuses'/
    -- sla_view_journal_statuses' logic inline instead of joining the global
    -- views, filtering by p_issue_id on issues/journals/journal_details
    -- *before* the window functions run. MySQL's optimizer -- unlike
    -- PostgreSQL's -- does not push an issue_id filter through a view
    -- containing window functions: joining the global views here would
    -- recompute FIRST_VALUE/LAG over every issue's entire journal history
    -- on every single call, then join a multi-million-row calendar against
    -- that unfiltered result. Scoping to one issue up front keeps both sides
    -- of the join small regardless of how many issues or how long a window.
    WITH RECURSIVE issue_journal_statuses AS (
        (
            SELECT DISTINCT issues.id AS issue_id,
                sla_get_date(FIRST_VALUE(issues.created_on) OVER w) AS issue_created_on,
                sla_get_date(FIRST_VALUE(issues.closed_on) OVER w) AS issue_closed_on,
                sla_get_date(FIRST_VALUE(issues.created_on) OVER w) AS journals_created_on,
                COALESCE(FIRST_VALUE(CAST(journal_details.old_value AS SIGNED)) OVER w, issues.status_id) AS journal_detail_old_value,
                COALESCE(FIRST_VALUE(CAST(journal_details.old_value AS SIGNED)) OVER w, issues.status_id) AS journal_detail_value
            FROM issues
            LEFT JOIN journals ON ( issues.id = journals.journalized_id )
            LEFT JOIN journal_details ON ( journals.id = journal_details.journal_id AND journal_details.property LIKE 'attr' AND journal_details.prop_key LIKE 'status_id' )
            WHERE issues.id = p_issue_id
            WINDOW w AS ( PARTITION BY issues.id ORDER BY (journal_details.id IS NULL), journal_details.id ASC )
        ) UNION (
            SELECT issues.id AS issue_id,
                sla_get_date(issues.created_on) AS issue_created_on,
                sla_get_date(issues.closed_on) AS issue_closed_on,
                sla_get_date(journals.created_on) AS journals_created_on,
                CAST(journal_details.old_value AS SIGNED) AS journal_detail_old_value,
                CAST(journal_details.value AS SIGNED) AS journal_detail_value
            FROM issues
            INNER JOIN journals ON ( issues.id = journals.journalized_id )
            INNER JOIN journal_details ON ( journals.id = journal_details.journal_id AND journal_details.property LIKE 'attr' AND journal_details.prop_key LIKE 'status_id' )
            WHERE issues.id = p_issue_id
        )
    ),
    issue_roll_statuses AS (
        (
            SELECT
                issue_id,
                journal_detail_old_value AS from_status_id,
                LAG(journals_created_on, 1, issue_created_on) OVER w2 AS from_status_date,
                journal_detail_value AS to_status_id,
                journals_created_on AS to_status_date
            FROM issue_journal_statuses
            WINDOW w2 AS ( PARTITION BY issue_id ORDER BY journals_created_on ASC )
        ) UNION (
            SELECT
                issue_id,
                FIRST_VALUE(journal_detail_value) OVER w3 AS from_status_id,
                FIRST_VALUE(journals_created_on) OVER w3 AS from_status_date,
                FIRST_VALUE(journal_detail_value) OVER w3 AS to_status_id,
                COALESCE(issue_closed_on, sla_get_date(NOW())) AS to_status_date
            FROM issue_journal_statuses
            WINDOW w3 AS ( PARTITION BY issue_id ORDER BY journals_created_on DESC )
        )
    ),
    seq AS (
        SELECT 0 AS n
        UNION ALL
        SELECT n + 1 FROM seq WHERE n < v_window_days
    )
    SELECT COALESCE(SUM(
      GREATEST(0, TIMESTAMPDIFF(MINUTE,
        GREATEST(issue_roll_statuses.from_status_date, TIMESTAMP(calendar.day_date, sla_schedules.start_time), v_window_start),
        LEAST(issue_roll_statuses.to_status_date, TIMESTAMP(calendar.day_date, sla_schedules.end_time) + INTERVAL 1 MINUTE, v_window_end + INTERVAL 1 MINUTE)
      ))
    ), 0)
    INTO v_new_spent
    FROM
      (
        SELECT DATE_ADD(DATE(v_window_start), INTERVAL n DAY) AS day_date
        FROM seq
      ) AS calendar
    INNER JOIN sla_schedules
      ON (
        -- PostgreSQL DATE_PART('dow', ...) is 0=Sunday..6=Saturday.
        -- MySQL DAYOFWEEK() is 1=Sunday..7=Saturday, hence the "- 1".
        (DAYOFWEEK(calendar.day_date) - 1) = sla_schedules.dow
      )
    CROSS JOIN issue_roll_statuses
    INNER JOIN sla_calendars
      ON (sla_calendars.id = sla_schedules.sla_calendar_id)
    INNER JOIN sla_levels
      ON (sla_levels.sla_calendar_id = sla_calendars.id AND sla_levels.id = v_cache_sla_level_id)
    INNER JOIN sla_project_trackers
      ON (sla_project_trackers.sla_id = sla_levels.sla_id)
    WHERE
      issue_roll_statuses.from_status_id IN (
        SELECT DISTINCT sla_statuses.status_id FROM sla_statuses WHERE sla_statuses.sla_type_id = p_sla_type_id
      )
    AND
      sla_project_trackers.project_id = v_issue_project_id
    AND
      sla_project_trackers.tracker_id = v_issue_tracker_id
    AND
      -- Exclude dates defined in the holiday calendar
      calendar.day_date NOT IN (
        SELECT sla_holidays.`date`
        FROM sla_holidays
        INNER JOIN sla_calendar_holidays
          ON (sla_calendar_holidays.sla_holiday_id = sla_holidays.id)
        WHERE sla_calendar_holidays.sla_calendar_id = sla_calendars.id
          AND NOT sla_calendar_holidays.`match`
      )
    AND
      -- Only keep (day, schedule, status-interval) triples that actually overlap
      GREATEST(issue_roll_statuses.from_status_date, TIMESTAMP(calendar.day_date, sla_schedules.start_time), v_window_start)
      <
      LEAST(issue_roll_statuses.to_status_date, TIMESTAMP(calendar.day_date, sla_schedules.end_time) + INTERVAL 1 MINUTE, v_window_end + INTERVAL 1 MINUTE);

    -- Safety check: Spent time cannot be negative
    IF ( v_new_spent IS NULL OR v_new_spent < 0 ) THEN
        SET v_new_spent = 0;
    END IF;

    -- Persist the results: Insert new record or increment 'spent' minutes on conflict
    INSERT INTO sla_cache_spents (
      sla_cache_id, project_id, issue_id, sla_type_id, spent, created_on, updated_on
    ) VALUES (
      v_cache_id, v_issue_project_id, p_issue_id, p_sla_type_id, v_new_spent, v_current_timestamp, v_current_timestamp
    )
    ON DUPLICATE KEY UPDATE
      updated_on = v_current_timestamp,
      spent = spent + v_new_spent;

    -- Mirrors the PostgreSQL version: returns the newly computed delta for
    -- this window, not the accumulated total now stored in sla_cache_spents.
    RETURN v_new_spent;
END
