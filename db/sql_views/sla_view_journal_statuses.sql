-- File: redmine_sla/db/sql_views/sla_view_journal_statuses.sql
-- Normalize issue status history from journals so that SLA logic can easily
-- determine each status interval (initial status + subsequent transitions).
CREATE OR REPLACE VIEW sla_view_journal_statuses AS
(
    -- Always include the initial status at the issue creation date,
    -- even if there is no explicit status change journal yet.
    SELECT DISTINCT issues.id AS issue_id,
        sla_get_date(first_value(issues.created_on) OVER window_journals) AS issue_created_on,
        sla_get_date(first_value(issues.closed_on) OVER window_journals) AS issue_closed_on,
        sla_get_date(first_value(issues.created_on) OVER window_journals) AS journals_created_on,
        COALESCE(first_value(journal_details.old_value::integer) OVER window_journals, issues.status_id) AS journal_detail_old_value,
        COALESCE(first_value(journal_details.old_value::integer) OVER window_journals, issues.status_id) AS journal_detail_value    FROM issues
    LEFT JOIN journals ON ( issues.id = journals.journalized_id )
    LEFT JOIN journal_details ON ( journals.id = journal_details.journal_id AND journal_details.property LIKE 'attr' AND journal_details.prop_key LIKE 'status_id' )
    WINDOW window_journals AS (PARTITION BY issues.id ORDER BY journal_details.id ASC NULLS LAST )
) UNION (
    -- Then add all subsequent status changes recorded in journals,
    -- so that each transition can be processed by SLA computations.
    SELECT issues.id AS issue_id,
        sla_get_date(issues.created_on) AS issue_created_on,
        sla_get_date(issues.closed_on) AS issue_closed_on,
        sla_get_date(journals.created_on) AS journals_created_on,
        journal_details.old_value::integer AS journal_detail_old_value,
        journal_details.value::integer AS journal_detail_value
    FROM issues
    INNER JOIN journals ON ( issues.id = journals.journalized_id )
    INNER JOIN journal_details ON ( journals.id = journal_details.journal_id AND journal_details.property LIKE 'attr' AND journal_details.prop_key LIKE 'status_id' )
)