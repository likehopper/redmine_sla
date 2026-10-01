-- SPDX-License-Identifier: GPL-2.0-or-later
--
-- Redmine SLA - service level agreement plugin
--
-- This program is free software; you can redistribute it and/or
-- modify it under the terms of the GNU General Public License
-- as published by the Free Software Foundation; either version 2
-- of the License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program. If not, see <https://www.gnu.org/licenses/>.
-- File: redmine_sla/db/sql_views/postgresql/sla_view_roll_statuses.sql
-- Purpose:
--   Build continuous status intervals for each issue based on its journal
--   status history (from sla_view_journal_statuses). This view reconstructs
--   "from" and "to" statuses with their corresponding dates so that SLA
--   computations can easily determine how long an issue stayed in each status.

-- Issues journals rebuild, with database time zone
CREATE OR REPLACE VIEW sla_view_roll_statuses AS
(
  -- First and subsequent status changes:
  -- Each row represents a transition from one status to another,
  -- with the time interval during which the "from" status was active.
  SELECT
    issue_id AS issue_id,
    journal_detail_old_value AS from_status_id,
    LAG(journals_created_on, 1, issue_created_on) OVER window_status AS from_status_date,
    journal_detail_value AS to_status_id,
    journals_created_on AS to_status_date
  FROM sla_view_journal_statuses
  WINDOW window_status AS (
    PARTITION BY issue_id
    ORDER BY journals_created_on ASC
  )
) UNION (
  -- Ensure we also have the "last" status interval:
  -- This covers the period from the last recorded status change
  -- until the issue is closed, or until "now" if it is still open.
  SELECT
    issue_id AS issue_id,
    FIRST_VALUE(journal_detail_value) OVER window_status AS from_status_id,
    FIRST_VALUE(journals_created_on) OVER window_status AS from_status_date,
    FIRST_VALUE(journal_detail_value) OVER window_status AS to_status_id,
    COALESCE(
      issue_closed_on,
      sla_get_date(NOW()::TIMESTAMP WITHOUT TIME ZONE)
    ) AS to_status_date
  FROM sla_view_journal_statuses
  WINDOW window_status AS (
    PARTITION BY issue_id
    ORDER BY journals_created_on DESC
  )
);