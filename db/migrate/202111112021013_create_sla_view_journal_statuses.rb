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
# File: redmine_sla/db/migrate/202111112021013_create_sla_view_journal_statuses.rb
# Purpose:
#   Deploy the SQL view `sla_view_journal_statuses`, which normalizes issue
#   status changes extracted from Redmine journals. The view definition is
#   stored per-dialect under `db/sql_views/<adapter>/sla_view_journal_statuses.sql`
#   and loaded using a reversible migration so it can be dropped cleanly on rollback.

class CreateSlaViewJournalStatuses < ActiveRecord::Migration[5.2]

  def change

    reversible do |dir|

      dir.up do
        # Create the SQL view from the dialect-specific SQL file
        execute RedmineSla::DbDialect.view_sql('sla_view_journal_statuses')
        say "Created view sla_view_journal_statuses"
      end

      dir.down do
        # Drop the view when rolling back the migration
        if RedmineSla::DbDialect.adapter == :mysql
          execute "DROP VIEW IF EXISTS sla_view_journal_statuses ;"
        else
          execute "DROP VIEW IF EXISTS public.sla_view_journal_statuses CASCADE ;"
        end
        say "Dropped view sla_view_journal_statuses"
      end

    end

  end

end