DROP VIEW IF EXISTS sla_view_journal_statuses CASCADE ;
CREATE VIEW sla_view_journal_statuses
-- Simplified the selection of journals for statuses
AS
SELECT
	issues.id::integer AS issue_id,
  sla_get_date(issues.created_on::TIMESTAMP WITHOUT TIME ZONE) AS issue_created_on,
  sla_get_date(issues.closed_on::TIMESTAMP WITHOUT TIME ZONE) AS issue_closed_on,
	sla_get_date(journals.created_on::TIMESTAMP WITHOUT TIME ZONE) AS journals_created_on,
	journal_details.old_value::integer AS journal_detail_old_value,
  journal_details.value::integer AS journal_detail_value
FROM issues
INNER JOIN journals
  ON ( issues.id = journals.journalized_id )
INNER JOIN journal_details
	ON ( journals.id = journal_details.journal_id AND journal_details.property LIKE 'attr' AND journal_details.prop_key LIKE 'status_id' )