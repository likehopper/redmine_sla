-- File: redmine_sla/db/sql_functions/sla_get_level_overlap.sql
-- Check whether multiple SLA levels overlap for a given SLA (p_sla_id).
-- An overlap means that more than one schedule-level combination is valid
-- for the same minute within the evaluation window. This indicates that
-- the SLA definition is inconsistent or ambiguous.

CREATE OR REPLACE FUNCTION sla_get_level_overlap(p_sla_id INTEGER)
RETURNS BOOLEAN
LANGUAGE sql
AS $BODY$

-- Logic summary:
--   - Generate a minute-by-minute timeline for 7 days.
--   - Join this timeline with SLA schedules, calendars and levels.
--   - Filter only schedules that belong to the target SLA (via levels).
--   - Detect whether more than one matching SLA level exists at the same minute.
--   - If at least one minute has COUNT(*) > 1, return TRUE (overlap detected).

SELECT DISTINCT TRUE
FROM
    -- Generate all minutes in the next 7 days.
    -- A 7-day period is sufficient to detect weekly schedule overlaps.
    (
      SELECT generate_series(
        NOW(),
        NOW() + INTERVAL '7 days',
        '1 minute'
      ) AS minutes
    ) AS "calendrier"

    INNER JOIN "sla_schedules"
      ON (
        DATE_PART('dow', "calendrier"."minutes") = "sla_schedules"."dow"
        AND "calendrier"."minutes"::TIME BETWEEN "sla_schedules"."start_time"
                                            AND "sla_schedules"."end_time"
      )

    INNER JOIN "sla_calendars"
      ON ("sla_calendars"."id" = "sla_schedules"."sla_calendar_id")

    INNER JOIN "sla_levels"
      ON ("sla_levels"."sla_calendar_id" = "sla_calendars"."id")

    INNER JOIN "sla_project_trackers"
      ON ("sla_project_trackers"."sla_id" = "sla_levels"."sla_id")

WHERE
    -- Consider only levels belonging to the provided SLA
    "sla_levels"."sla_id" = p_sla_id

    -- Schedule must be marked as "match" (active)
    AND "sla_schedules"."match"

GROUP BY
    "calendrier"."minutes"

HAVING COUNT(*) > 1 ;   -- More than one SLA level applies at the same minute → overlap detected

$BODY$;