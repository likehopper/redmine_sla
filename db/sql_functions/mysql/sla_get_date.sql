-- File: redmine_sla/db/sql_functions/mysql/sla_get_date.sql
-- MySQL 8.0+ / MariaDB 10.2+ equivalent of the PostgreSQL sla_get_date function.
-- Normalize a timestamp to the SLA timezone and truncate to the minute.
-- This function is used everywhere a consistent datetime reference is required.
--
-- Requirement: the MySQL time zone tables must be loaded for CONVERT_TZ to
-- resolve IANA zone names (e.g. `mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root mysql`).
-- If they are not loaded, CONVERT_TZ silently returns NULL.
--
-- No DROP FUNCTION / DELIMITER here: this file must be exactly one statement.
-- MySQL has no CREATE OR REPLACE FUNCTION (unlike MariaDB), so the migration
-- issues DROP FUNCTION IF EXISTS separately before executing this file, and
-- DELIMITER is a mysql-CLI-only directive -- Rails' mysql2 driver sends this
-- file's content as a single query directly to the server, which understands
-- the BEGIN...END block's internal semicolons without any delimiter switch.
CREATE FUNCTION sla_get_date(p_date DATETIME)
RETURNS DATETIME
READS SQL DATA
NOT DETERMINISTIC
BEGIN
    DECLARE v_timezone VARCHAR(64);

    -- Extract the SLA timezone from Redmine plugin settings (YAML-like blob).
    -- REGEXP_SUBSTR has no capture-group extraction in MySQL and "." does not
    -- cross the newlines in that YAML blob, so the zone name is isolated by
    -- matching "sla_time_zone: <zone>" on its own line, then trimming the prefix.
    SELECT COALESCE(
        (
            SELECT SUBSTRING(
                REGEXP_SUBSTR(value, 'sla_time_zone: [a-zA-Z/]+'),
                LENGTH('sla_time_zone: ') + 1
            )
            FROM settings
            WHERE name LIKE 'plugin_redmine_sla'
        ),
        -- Default timezone if none is configured
        'Etc/UTC'
    ) INTO v_timezone;

    -- p_date is always interpreted as UTC first, then converted to the
    -- configured timezone, then truncated to the minute (SLA granularity).
    RETURN CAST(
        DATE_FORMAT(CONVERT_TZ(p_date, 'UTC', v_timezone), '%Y-%m-%d %H:%i:00')
        AS DATETIME
    );
END
