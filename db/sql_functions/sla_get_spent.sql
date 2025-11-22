-- File: redmine_sla/db/sql_functions/sla_get_spent.sql
-- Compute the number of SLA-eligible minutes spent on an issue,
-- starting from its SLA start date and following SLA calendars, schedules,
-- holidays, and pauses. The result is the total active time (in minutes)
-- counted toward the SLA.

CREATE OR REPLACE FUNCTION sla_get_spent(
    p_issue_id INTEGER,             -- Issue whose SLA time must be computed
    p_refresh_force BOOLEAN DEFAULT FALSE  -- When TRUE, forces recalculation even if cache exists
)
RETURNS sla_cache_spents
AS
$BODY$
DECLARE
    v_sla_cache_spent sla_cache_spents;            -- Final returned record
    v_sla_cache sla_caches;                        -- Cached SLA level/start date
    v_issue_status_id INTEGER;                     -- Current issue status
    v_current_timestamp TIMESTAMP WITHOUT TIME ZONE;   -- Normalized evaluation timestamp
    v_last_spent TIMESTAMP WITHOUT TIME ZONE;          -- Last timestamp where SLA spent was updated
    v_spent BIGINT;                                -- Number of minutes consumed
BEGIN
    RAISE DEBUG 'sla_get_spent | BEGIN ------';

    ---------------------------------------------------------------------------
    -- Mandatory check: issue ID must be provided
    ---------------------------------------------------------------------------
    IF p_issue_id IS NULL THEN
        RAISE DEBUG 'sla_get_spent | p_issue_id is NULL';
        RETURN NULL;
    END IF;

    RAISE DEBUG 'sla_get_spent | p_issue_id = %', p_issue_id;

    ---------------------------------------------------------------------------
    -- Normalize current timestamp according to SLA timezone
    ---------------------------------------------------------------------------
    v_current_timestamp := sla_get_date(NOW()::TIMESTAMP WITHOUT TIME ZONE);
    RAISE DEBUG 'sla_get_spent | v_current_timestamp = %', v_current_timestamp;

    ---------------------------------------------------------------------------
    -- Load SLA cache entry (SLA level + start date)
    ---------------------------------------------------------------------------
    SELECT *
    INTO v_sla_cache
    FROM sla_caches
    WHERE issue_id = p_issue_id;

    IF v_sla_cache IS NULL THEN
        -- If no SLA level exists yet, compute it now
        RAISE DEBUG 'sla_get_spent | No SLA cache found → computing SLA level first';
        PERFORM sla_get_level(p_issue_id);
        SELECT *
        INTO v_sla_cache
        FROM sla_caches
        WHERE issue_id = p_issue_id;
    END IF;

    -- If still NULL after recomputation → no SLA applies for this issue
    IF v_sla_cache IS NULL THEN
        RAISE DEBUG 'sla_get_spent | No SLA level available → return NULL';
        RETURN NULL;
    END IF;

    RAISE DEBUG 'sla_get_spent | SLA start_date = %', v_sla_cache.start_date;

    ---------------------------------------------------------------------------
    -- Try to load existing spent cache
    ---------------------------------------------------------------------------
    SELECT *
    INTO v_sla_cache_spent
    FROM sla_cache_spents
    WHERE issue_id = p_issue_id;

    -- Reuse cached result unless refresh is forced
    IF v_sla_cache_spent IS NOT NULL AND NOT p_refresh_force THEN
        RAISE DEBUG 'sla_get_spent | Returning cached SLA spent';
        RETURN v_sla_cache_spent;
    END IF;

    ---------------------------------------------------------------------------
    -- Load last status of the issue (status controls SLA pauses/stops)
    ---------------------------------------------------------------------------
    SELECT status_id
    INTO v_issue_status_id
    FROM issues
    WHERE id = p_issue_id;

    RAISE DEBUG 'sla_get_spent | v_issue_status_id = %', v_issue_status_id;

    ---------------------------------------------------------------------------
    -- Determine where the spent counter must resume from
    -- If a previous record exists → resume from last_spent
    -- Otherwise start from SLA start_date
    ---------------------------------------------------------------------------
    IF v_sla_cache_spent IS NOT NULL THEN
        v_last_spent := v_sla_cache_spent.last_spent;
    ELSE
        v_last_spent := v_sla_cache.start_date;
    END IF;

    RAISE DEBUG 'sla_get_spent | v_last_spent = %', v_last_spent;

    ---------------------------------------------------------------------------
    -- Compute number of valid SLA minutes between v_last_spent and NOW()
    -- using the SLA calendar, schedules, holidays and status pauses.
    --
    -- This is the core computation: it enumerates all minutes between the
    -- start date and now, filters them through SLA rules and counts the valid ones.
    ---------------------------------------------------------------------------
    SELECT COUNT(*)
    INTO v_spent
    FROM (
        SELECT generate_series(
            v_last_spent,
            v_current_timestamp,
            '1 minute'
        ) AS minutes
    ) AS cal

    INNER JOIN sla_schedules
        ON (
            DATE_PART('dow', cal.minutes) = sla_schedules.dow
            AND cal.minutes::time BETWEEN sla_schedules.start_time
                                     AND sla_schedules.end_time
        )

    INNER JOIN sla_calendars
        ON sla_calendars.id = sla_schedules.sla_calendar_id

    INNER JOIN sla_levels
        ON sla_levels.sla_calendar_id = sla_calendars.id

    INNER JOIN sla_project_trackers
        ON sla_project_trackers.sla_id = sla_levels.sla_id

    WHERE
        sla_project_trackers.project_id = v_sla_cache.project_id
        AND sla_project_trackers.tracker_id = v_sla_cache.tracker_id
        AND (
            sla_schedules.match
            OR EXISTS (
                SELECT 1
                FROM sla_calendar_holidays sch
                INNER JOIN sla_holidays sh
                    ON sh.id = sch.sla_holiday_id AND sch.match
                WHERE
                    sch.sla_calendar_id = sla_schedules.sla_calendar_id
                    AND sh.date = cal.minutes::date
            )
        )
        AND cal.minutes::date NOT IN (
            SELECT sh.date
            FROM sla_holidays sh
            INNER JOIN sla_calendar_holidays sch
                ON sch.sla_holiday_id = sh.id
            WHERE
                sch.sla_calendar_id = sla_calendars.id
                AND NOT sch.match
        )
        -- Issue status restrictions: if SLA is paused for this status,
        -- do not count minutes when the issue is in such a status.
        AND NOT EXISTS (
            SELECT 1
            FROM sla_statuses
            WHERE sla_statuses.sla_id = sla_levels.sla_id
              AND sla_statuses.status_id = v_issue_status_id
              AND NOT sla_statuses.match
        );

    RAISE DEBUG 'sla_get_spent | Computed minutes = %', v_spent;

    ---------------------------------------------------------------------------
    -- Build or update cache entry
    ---------------------------------------------------------------------------
    INSERT INTO sla_cache_spents (
        issue_id,
        start_date,
        last_spent,
        spent,
        created_on,
        updated_on
    ) VALUES (
        p_issue_id,
        v_sla_cache.start_date,
        v_current_timestamp,
        v_spent,
        COALESCE(v_sla_cache_spent.created_on, v_current_timestamp),
        v_current_timestamp
    )

    ON CONFLICT (issue_id)
    DO UPDATE SET
        last_spent = EXCLUDED.last_spent,
        spent = EXCLUDED.spent,
        updated_on = EXCLUDED.updated_on
    RETURNING * INTO v_sla_cache_spent;

    RAISE DEBUG 'sla_get_spent | END ------';

    RETURN v_sla_cache_spent;

END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;