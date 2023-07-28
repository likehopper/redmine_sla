DROP VIEW IF EXISTS sla_view_journals CASCADE ;
CREATE VIEW sla_view_journals
-- Issues journals rebuild, with database time zone
AS
(
-- As starting point, we take the issues's creation date, missing in journals
SELECT
	issues.id::INTEGER AS issue_id,
	(1)::INTEGER AS from_status_id,
	sla_get_date(issues.created_on::TIMESTAMP WITHOUT TIME ZONE) AS from_status_date,
	(1)::INTEGER AS to_status_id,
	sla_get_date(issues.created_on::TIMESTAMP WITHOUT TIME ZONE) AS to_status_date
FROM
	issues
)
UNION
(
-- Grouping all status changes
SELECT
	j1.journalized_id::INTEGER AS issue_id,
	jd1.old_value::integer AS from_status_id,
	sla_get_date(COALESCE(
	(
		SELECT
			MAX(j2.created_on)
		FROM
			journals AS j2
		INNER JOIN
			journal_details AS jd2 ON ( j2.id = jd2.journal_id )
		WHERE
			j2.journalized_id = j1.journalized_id
		AND 
			j2.journalized_type LIKE 'Issue'		
		AND
			jd2.property LIKE 'attr'			
		AND
			jd2.prop_key LIKE 'status_id'			
		AND
			j2.id  < j1.id
	),i1.created_on)::TIMESTAMP WITHOUT TIME ZONE) AS from_status_date,
	jd1.value::integer AS to_status_id,
	sla_get_date(j1.created_on::TIMESTAMP WITHOUT TIME ZONE) AS to_status_date
FROM
	issues AS i1
INNER JOIN
	journals AS j1 ON ( i1.id = j1.journalized_id )
INNER JOIN
	journal_details AS jd1 ON ( j1.id = jd1.journal_id )
WHERE
	j1.journalized_type LIKE 'Issue'		
AND
	jd1.property LIKE 'attr'
AND
	jd1.prop_key LIKE 'status_id'
)
UNION
(
-- Make sure to get the last possible date, for get the last status, and especially for closed issues
SELECT
        i2.id::INTEGER AS issue_id,
        i2.status_id AS from_status_id,
        sla_get_date(COALESCE(
        (
                SELECT
                        MAX(j3.created_on)
                FROM
                        journals AS j3
                INNER JOIN
                        journal_details AS jd3 ON ( j3.id = jd3.journal_id )
                WHERE
                        j3.journalized_id = i2.id
                AND
                        j3.journalized_type LIKE 'Issue'
                AND
                        jd3.property LIKE 'attr'
                AND
                        jd3.prop_key LIKE 'status_id'
        ),i2.created_on)::TIMESTAMP WITHOUT TIME ZONE) AS from_status_date,
        i2.status_id AS to_status_id,
        sla_get_date(COALESCE( i2.closed_on, NOW() )::TIMESTAMP WITHOUT TIME ZONE ) AS to_status_date
FROM
        issues AS i2
)
-- We sort to make the parse easier
ORDER BY
	from_status_date ASC,
	to_status_date ASC
;