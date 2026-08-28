-- File: redmine_sla/db/sql_functions/sla_explain_spent.sql
-- Read-only diagnostic companion to sla_get_spent(): for a given issue and
-- SLA type, decomposes every status interval from sla_view_roll_statuses
-- DAY BY DAY, with whether that status is tracked for this SLA type,
-- whether that specific day is a declared holiday (and its name), and how
-- many business minutes it contributed that day (same schedule/holiday
-- constraints as sla_get_spent()) — without writing to sla_cache_spents.
--
-- Day-level granularity matters: a status interval that spans weeks (e.g. a
-- ticket sitting "in progress") would otherwise show a single aggregated
-- total, hiding whether a holiday in the middle of it reduced the count.
--
-- Used exclusively by the "Explain" action (SlaCachesController#explain)
-- to let a project SLA manager understand a ticket's spent-time calculation
-- on demand. Never called from the normal calculation path. Relies on the
-- issue's SLA level already being resolved in sla_caches (via sla_get_level
-- or sla_explain_level) — returns no rows if the issue has no SLA level.

CREATE OR REPLACE FUNCTION sla_explain_spent(p_issue_id INTEGER, p_sla_type_id INTEGER)
  RETURNS TABLE (
    from_status_id INTEGER,
    from_status_name VARCHAR,
    to_status_id INTEGER,
    to_status_name VARCHAR,
    from_status_date TIMESTAMP WITHOUT TIME ZONE,
    to_status_date TIMESTAMP WITHOUT TIME ZONE,
    tracked BOOLEAN,
    day DATE,
    is_holiday BOOLEAN,
    holiday_name VARCHAR,
    has_schedule BOOLEAN,
    minutes_counted BIGINT
  ) AS
$BODY$

  WITH sla_context AS (
    SELECT "sla_caches"."sla_level_id" AS sla_level_id
    FROM "sla_caches"
    WHERE "sla_caches"."issue_id" = p_issue_id
  ),

  tracked_statuses AS (
    SELECT DISTINCT "sla_statuses"."status_id" AS status_id
    FROM "sla_statuses"
    WHERE "sla_statuses"."sla_type_id" = p_sla_type_id
  ),

  -- One row per status interval (same as before), zero-length rows dropped.
  intervals AS (
    SELECT
      "roll"."from_status_id",
      "from_status"."name" AS from_status_name,
      "roll"."to_status_id",
      "to_status"."name" AS to_status_name,
      "roll"."from_status_date",
      "roll"."to_status_date",
      ( "roll"."from_status_id" IN ( SELECT status_id FROM tracked_statuses ) ) AS tracked
    FROM "sla_view_roll_statuses" "roll"
    LEFT JOIN "issue_statuses" "from_status" ON ( "from_status"."id" = "roll"."from_status_id" )
    LEFT JOIN "issue_statuses" "to_status" ON ( "to_status"."id" = "roll"."to_status_id" )
    WHERE "roll"."issue_id" = p_issue_id
      AND "roll"."to_status_date" > "roll"."from_status_date"
  ),

  -- Explode each TRACKED interval into one row per calendar day it touches
  -- (that's what reveals a holiday/weekend hidden inside it). An untracked
  -- interval always contributes 0 minutes regardless of how long it is --
  -- e.g. the trailing interval of a closed issue extends to NOW(), which
  -- could be months away -- so collapse it to a single representative row
  -- instead of one row per day.
  days AS (
    SELECT
      intervals.*,
      gs.day
    FROM intervals
    CROSS JOIN LATERAL (
      SELECT generate_series(
        DATE_TRUNC('day', intervals.from_status_date),
        CASE
          WHEN intervals.tracked THEN DATE_TRUNC('day', intervals.to_status_date - INTERVAL '1 minute')
          ELSE DATE_TRUNC('day', intervals.from_status_date)
        END,
        INTERVAL '1 day'
      )::date AS day
    ) gs
  )

  SELECT
    days.from_status_id,
    days.from_status_name,
    days.to_status_id,
    days.to_status_name,
    days.from_status_date,
    days.to_status_date,
    days.tracked,
    days.day,
    ( holiday_match.date IS NOT NULL ) AS is_holiday,
    holiday_match.holiday_name,
    -- No sla_schedules row at all for this day-of-week on the calendar
    -- (typically a weekend) — distinct from a holiday, which HAS a schedule
    -- but is explicitly excluded that specific date.
    EXISTS (
      SELECT 1 FROM "sla_schedules"
      WHERE "sla_schedules"."sla_calendar_id" = "sla_levels"."sla_calendar_id"
        AND "sla_schedules"."dow" = DATE_PART('dow', days.day)
        AND "sla_schedules"."match"
    ) AS has_schedule,
    COALESCE((
      SELECT COUNT(*)
      FROM (
        -- Clamp the day's minute-series to the actual interval boundaries,
        -- so a day that's only partially covered by this status isn't
        -- over/under-counted at its edges.
        SELECT generate_series(
          GREATEST(days.from_status_date, days.day::timestamp),
          LEAST(days.to_status_date - INTERVAL '1 minute', days.day::timestamp + INTERVAL '1 day' - INTERVAL '1 minute'),
          INTERVAL '1 minute'
        ) AS minute
      ) AS "window"
      INNER JOIN "sla_schedules"
        ON ( "sla_schedules"."sla_calendar_id" = "sla_levels"."sla_calendar_id"
             AND DATE_PART('dow', "window"."minute") = "sla_schedules"."dow"
             AND "window"."minute"::TIME BETWEEN "sla_schedules"."start_time" AND "sla_schedules"."end_time" )
      WHERE days.tracked AND holiday_match.date IS NULL
    ), 0) AS minutes_counted
  FROM days
  CROSS JOIN sla_context
  INNER JOIN "sla_levels" ON ( "sla_levels"."id" = sla_context.sla_level_id )
  LEFT JOIN (
    SELECT "sla_holidays"."date", "sla_holidays"."name" AS holiday_name, "sla_calendar_holidays"."sla_calendar_id"
    FROM "sla_holidays"
    INNER JOIN "sla_calendar_holidays" ON ( "sla_calendar_holidays"."sla_holiday_id" = "sla_holidays"."id" )
    WHERE NOT "sla_calendar_holidays"."match"
  ) AS holiday_match
    ON ( holiday_match."sla_calendar_id" = "sla_levels"."sla_calendar_id" AND holiday_match."date" = days.day )
  ORDER BY days.from_status_date, days.day ;

$BODY$
  LANGUAGE sql STABLE;
