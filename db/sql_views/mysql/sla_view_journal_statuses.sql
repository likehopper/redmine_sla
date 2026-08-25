-- File: redmine_sla/db/sql_views/mysql/sla_view_journal_statuses.sql
-- MySQL 8.0+ / MariaDB 10.2+ equivalent of the PostgreSQL sla_view_journal_statuses view.
-- Normalize issue status history from journals so that SLA logic can easily
-- determine each status interval (initial status + subsequent transitions).
CREATE OR REPLACE VIEW sla_view_journal_statuses AS
(
    -- Always include the initial status at the issue creation date,
    -- even if there is no explicit status change journal yet.
    --
    -- PostgreSQL's default ASC ordering already sorts NULLs last, but MySQL's
    -- default sorts NULLs first. `journal_details.id` is NULL for every journal
    -- that is not a status change, so without the explicit `(... IS NULL)`
    -- tiebreaker below, MySQL could pick a non-status-change journal as the
    -- "first" row of the partition instead of the earliest real status change.
    SELECT DISTINCT issues.id AS issue_id,
        sla_get_date(FIRST_VALUE(issues.created_on) OVER window_journals) AS issue_created_on,
        sla_get_date(FIRST_VALUE(issues.closed_on) OVER window_journals) AS issue_closed_on,
        sla_get_date(FIRST_VALUE(issues.created_on) OVER window_journals) AS journals_created_on,
        COALESCE(FIRST_VALUE(CAST(journal_details.old_value AS SIGNED)) OVER window_journals, issues.status_id) AS journal_detail_old_value,
        COALESCE(FIRST_VALUE(CAST(journal_details.old_value AS SIGNED)) OVER window_journals, issues.status_id) AS journal_detail_value
    FROM issues
    LEFT JOIN journals ON ( issues.id = journals.journalized_id )
    LEFT JOIN journal_details ON ( journals.id = journal_details.journal_id AND journal_details.property LIKE 'attr' AND journal_details.prop_key LIKE 'status_id' )
    WINDOW window_journals AS (
      PARTITION BY issues.id
      ORDER BY (journal_details.id IS NULL), journal_details.id ASC
    )
) UNION (
    -- Then add all subsequent status changes recorded in journals,
    -- so that each transition can be processed by SLA computations.
    SELECT issues.id AS issue_id,
        sla_get_date(issues.created_on) AS issue_created_on,
        sla_get_date(issues.closed_on) AS issue_closed_on,
        sla_get_date(journals.created_on) AS journals_created_on,
        CAST(journal_details.old_value AS SIGNED) AS journal_detail_old_value,
        CAST(journal_details.value AS SIGNED) AS journal_detail_value
    FROM issues
    INNER JOIN journals ON ( issues.id = journals.journalized_id )
    INNER JOIN journal_details ON ( journals.id = journal_details.journal_id AND journal_details.property LIKE 'attr' AND journal_details.prop_key LIKE 'status_id' )
);
