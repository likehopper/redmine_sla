-- File: redmine_sla/db/sql_functions/mysql/sla_get_level_overlap.sql
-- MySQL 8.0+ / MariaDB 10.2+ equivalent of the PostgreSQL sla_get_level_overlap
-- function. Check whether multiple SLA levels overlap for a given SLA (p_sla_id).
-- Mirrors the PostgreSQL version's behaviour: returns TRUE if an overlapping
-- minute is found, NULL otherwise (no overlap detected).
--
-- No DROP FUNCTION / DELIMITER here: this file must be exactly one statement
-- (see sla_get_date.sql for why). The migration issues DROP FUNCTION IF
-- EXISTS separately before executing this file.
CREATE FUNCTION sla_get_level_overlap(p_sla_id INT)
RETURNS BOOLEAN
READS SQL DATA
NOT DETERMINISTIC
BEGIN
    DECLARE v_overlap BOOLEAN DEFAULT NULL;
    DECLARE v_start DATETIME DEFAULT NOW();
    -- A SELECT ... INTO that matches zero rows raises a "no data" (SQLSTATE 02000)
    -- condition in MySQL/MariaDB; without this handler the function would abort
    -- instead of returning NULL the way the PostgreSQL version does.
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_overlap = NULL;

    -- Generate all minutes in the next 7 days (0..10080 inclusive, matching
    -- PostgreSQL's generate_series(NOW(), NOW() + INTERVAL '7 days', '1 minute')).
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
    -- window is bigger than the default limit of 1000. Callers must run
    -- RedmineSla::DbDialect.ensure_recursion_depth! on the connection before
    -- calling this function: the session variable controlling the cap is
    -- named differently per engine, and a stored FUNCTION can't pick between
    -- them with dynamic SQL (MySQL/MariaDB disallow PREPARE/EXECUTE there)
    -- -- even a SET naming the other engine's variable inside a dead IF
    -- branch still fails MariaDB's CREATE FUNCTION, which validates every
    -- SET target eagerly.

    SELECT DISTINCT TRUE
    INTO v_overlap
    FROM
      (
        WITH RECURSIVE seq AS (
          SELECT 0 AS n
          UNION ALL
          SELECT n + 1 FROM seq WHERE n < 10080
        )
        SELECT DATE_ADD(v_start, INTERVAL n MINUTE) AS minutes
        FROM seq
      ) AS calendar
      INNER JOIN sla_schedules
        ON (
          -- PostgreSQL DATE_PART('dow', ...) is 0=Sunday..6=Saturday.
          -- MySQL DAYOFWEEK() is 1=Sunday..7=Saturday, hence the "- 1".
          -- (MySQL WEEKDAY() is 0=Monday..6=Sunday and must NOT be used here.)
          (DAYOFWEEK(calendar.minutes) - 1) = sla_schedules.dow
          AND TIME(calendar.minutes) BETWEEN sla_schedules.start_time AND sla_schedules.end_time
        )
      INNER JOIN sla_calendars
        ON (sla_calendars.id = sla_schedules.sla_calendar_id)
      INNER JOIN sla_levels
        ON (sla_levels.sla_calendar_id = sla_calendars.id)
      INNER JOIN sla_project_trackers
        ON (sla_project_trackers.sla_id = sla_levels.sla_id)
    WHERE
      sla_levels.sla_id = p_sla_id
      AND sla_schedules.`match`
    GROUP BY calendar.minutes
    HAVING COUNT(*) > 1
    LIMIT 1;

    RETURN v_overlap;
END
