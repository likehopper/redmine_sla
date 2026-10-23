# SPDX-License-Identifier: GPL-2.0-or-later
#
# Redmine SLA - service level agreement plugin
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
# File: redmine_sla/db/migrate/202111112021024_count_reopened_issues_spent.rb
# Purpose:
#   Redmine keeps closed_on, as the last closing date, when an issue is
#   reopened. SLA spent time stopped there, so it no longer counted for a
#   reopened issue. Use closed_on only while the issue is closed:
#     - redeploy sla_view_journal_statuses and sla_get_spent,
#     - purge the spent cache of reopened issues, which is incremental and
#       missed the time since their reopening; it is recalculated on demand.

class CountReopenedIssuesSpent < ActiveRecord::Migration[5.2]

  def up
    # sla_view_roll_statuses depends on this view and keeps the same columns.
    execute RedmineSla::DbDialect.view_sql('sla_view_journal_statuses')
    say "Redeployed view sla_view_journal_statuses"

    # MySQL has no CREATE OR REPLACE FUNCTION (see 202111112021015).
    execute "DROP FUNCTION IF EXISTS sla_get_spent ;" if RedmineSla::DbDialect.adapter == :mysql
    execute RedmineSla::DbDialect.function_sql('sla_get_spent')
    say "Redeployed function sla_get_spent"

    execute <<~SQL
      DELETE FROM sla_cache_spents
      WHERE issue_id IN (
        SELECT issues.id FROM issues
        INNER JOIN issue_statuses ON ( issue_statuses.id = issues.status_id )
        WHERE NOT issue_statuses.is_closed AND issues.closed_on IS NOT NULL
      )
    SQL
    say "Purged SLA spent cache of reopened issues"
  end

  def down
    # Nothing to restore: the purged cache is recomputable, and the
    # redeployed view and function stay correct for earlier schema versions.
  end

end
