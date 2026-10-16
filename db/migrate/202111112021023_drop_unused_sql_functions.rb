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
# File: redmine_sla/db/migrate/202111112021023_drop_unused_sql_functions.rb
# Purpose:
#   Drop SQL functions nothing calls anymore:
#     - sla_get_level_overlap: superseded by the SlaSchedule overlap
#       validation; it was also left behind by an uninstall,
#     - sla_explain_level / sla_explain_spent (PostgreSQL only): superseded
#       by the RedmineSla::SlaExplanation service.

class DropUnusedSqlFunctions < ActiveRecord::Migration[5.2]

  def up
    if RedmineSla::DbDialect.adapter == :postgresql
      execute "DROP FUNCTION IF EXISTS sla_get_level_overlap(INTEGER) ;"
      execute "DROP FUNCTION IF EXISTS sla_explain_spent(INTEGER, INTEGER) ;"
      execute "DROP FUNCTION IF EXISTS sla_explain_level(INTEGER) ;"
    else
      execute "DROP FUNCTION IF EXISTS sla_get_level_overlap ;"
    end
    say "Dropped unused SQL functions"
  end

  def down
    # Nothing to restore: these functions were not used.
  end

end
