-- File: redmine_sla/db/sql_functions/sla_explain_level.sql
-- Read-only diagnostic companion to sla_get_level(): for a given issue,
-- lists every SLA level candidate (via the project/tracker's SLA
-- configuration) and whether/when it would match within the same 7-day
-- search window used by sla_get_level(), without writing to sla_caches.
--
-- Used exclusively by the "Explain" action (SlaCachesController#explain)
-- to let a project SLA manager understand a ticket's SLA level selection
-- on demand. Never called from the normal calculation path.

CREATE OR REPLACE FUNCTION sla_explain_level(p_issue_id INTEGER)
  RETURNS TABLE (
    sla_level_id INTEGER,
    sla_level_name VARCHAR,
    sla_calendar_id INTEGER,
    sla_calendar_name VARCHAR,
    matched BOOLEAN,
    start_date TIMESTAMP WITHOUT TIME ZONE,
    selected BOOLEAN
  ) AS
$BODY$

  WITH issue_info AS (
    SELECT
      "issues"."id" AS issue_id,
      "issues"."project_id" AS project_id,
      "issues"."tracker_id" AS tracker_id,
      sla_get_date("issues"."created_on") AS created_on
    FROM "issues"
    WHERE "issues"."id" = p_issue_id
  ),

  -- Every SLA level that could apply to this issue's project/tracker,
  -- regardless of whether it actually matches within the search window.
  candidate_levels AS (
    SELECT DISTINCT
      "sla_levels"."id" AS sla_level_id,
      "sla_levels"."name" AS sla_level_name,
      "sla_calendars"."id" AS sla_calendar_id,
      "sla_calendars"."name" AS sla_calendar_name
    FROM issue_info
    INNER JOIN "sla_project_trackers"
      ON ( "sla_project_trackers"."project_id" = issue_info.project_id
           AND "sla_project_trackers"."tracker_id" = issue_info.tracker_id )
    INNER JOIN "sla_levels"
      ON ( "sla_levels"."sla_id" = "sla_project_trackers"."sla_id" )
    INNER JOIN "sla_calendars"
      ON ( "sla_calendars"."id" = "sla_levels"."sla_calendar_id" )
  ),

  -- Same matching logic as sla_get_level(), but computed per candidate
  -- level instead of stopping at the first overall match.
  first_match AS (
    SELECT
      candidate_levels.sla_level_id,
      MIN("calendar"."minutes") AS start_date
    FROM candidate_levels
    CROSS JOIN issue_info
    INNER JOIN "sla_schedules"
      ON ( "sla_schedules"."sla_calendar_id" = candidate_levels.sla_calendar_id )
    CROSS JOIN LATERAL (
      SELECT generate_series(
        issue_info.created_on,
        issue_info.created_on + INTERVAL '7 days',
        '1 minute'
      ) AS minutes
    ) AS "calendar"
    LEFT JOIN (
      SELECT "date", "sla_calendar_id"
      FROM "sla_calendar_holidays"
      INNER JOIN "sla_holidays"
        ON ( "sla_holidays"."id" = "sla_calendar_holidays"."sla_holiday_id"
             AND "sla_calendar_holidays"."match" )
    ) AS "sla_holiday_match"
      ON ( "sla_holiday_match"."sla_calendar_id" = "sla_schedules"."sla_calendar_id"
           AND "sla_holiday_match"."date" = "calendar"."minutes"::DATE )
    WHERE
      DATE_PART('dow', "calendar"."minutes") = "sla_schedules"."dow"
      AND "calendar"."minutes"::TIME BETWEEN "sla_schedules"."start_time" AND "sla_schedules"."end_time"
      AND "calendar"."minutes"::DATE NOT IN (
        SELECT "sla_holidays"."date"
        FROM "sla_holidays"
        INNER JOIN "sla_calendar_holidays"
          ON ( "sla_holidays"."id" = "sla_calendar_holidays"."sla_holiday_id" )
        WHERE
          "sla_calendar_holidays"."sla_calendar_id" = candidate_levels.sla_calendar_id
          AND NOT "sla_calendar_holidays"."match"
      )
      AND (
        "sla_schedules"."match"
        OR "sla_holiday_match"."date" = "calendar"."minutes"::DATE
      )
    GROUP BY candidate_levels.sla_level_id
  )

  SELECT
    candidate_levels.sla_level_id,
    candidate_levels.sla_level_name,
    candidate_levels.sla_calendar_id,
    candidate_levels.sla_calendar_name,
    ( first_match.start_date IS NOT NULL ) AS matched,
    first_match.start_date,
    ( first_match.start_date IS NOT NULL
      AND first_match.start_date = ( SELECT MIN(start_date) FROM first_match ) ) AS selected
  FROM candidate_levels
  LEFT JOIN first_match ON ( first_match.sla_level_id = candidate_levels.sla_level_id )
  ORDER BY ( first_match.start_date IS NULL ), first_match.start_date ;

$BODY$
  LANGUAGE sql STABLE;
