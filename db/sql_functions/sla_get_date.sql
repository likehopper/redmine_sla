DROP FUNCTION IF EXISTS sla_get_date CASCADE ;
CREATE FUNCTION sla_get_date(p_date TIMESTAMP) RETURNS TIMESTAMP
    LANGUAGE sql
    AS $$
-- SET SESSION timezone TO 'Etc/UTC';
SELECT DATE_TRUNC( 'MINUTE', TIMEZONE(
  (
    SELECT COALESCE( 
      (
        SELECT SUBSTRING( value FROM 'sla_time_zone: ([a-z,A-Z,/]*)')
        FROM settings
        WHERE name LIKE 'plugin_redmine_sla'
      ), 'Etc/UTC' )
  ), p_date AT TIME ZONE 'Etc/UTC'
) )
;$$;