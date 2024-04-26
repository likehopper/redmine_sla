-- Checks if SLA levels overlap
CREATE OR REPLACE FUNCTION sla_get_level_overlap(p_sla_id INTEGER) RETURNS BOOLEAN
  LANGUAGE sql
  AS $BODY$
SELECT DISTINCT TRUE
  FROM            
    ( SELECT generate_series( NOW(), NOW() + INTERVAL '7 days', '1 minute') AS minutes ) AS "calendrier"
  INNER JOIN
    "sla_schedules"
      ON ( DATE_PART('dow',"calendrier"."minutes") = "sla_schedules"."dow" AND "calendrier"."minutes"::TIME BETWEEN "sla_schedules"."start_time" AND "sla_schedules"."end_time" )
  INNER JOIN
    "sla_calendars"
      ON ( "sla_calendars"."id" = "sla_schedules"."sla_calendar_id" )
  INNER JOIN
    "sla_levels"
      ON ( "sla_levels"."sla_calendar_id" = "sla_calendars"."id" )
  INNER JOIN
    "sla_project_trackers"
      ON ( "sla_project_trackers"."sla_id" = "sla_levels"."sla_id" )
  WHERE
    "sla_levels"."sla_id" = p_sla_id
  AND
    ( "sla_schedules"."match" )
  GROUP BY
    "calendrier"."minutes"
  HAVING COUNT(*)>1 ;
$BODY$