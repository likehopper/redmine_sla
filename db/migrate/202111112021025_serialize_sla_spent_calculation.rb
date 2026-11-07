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
# File: redmine_sla/db/migrate/202111112021025_serialize_sla_spent_calculation.rb
# Purpose:
#   sla_get_spent adds the minutes elapsed since its last run to the stored
#   total. Two concurrent calls for the same issue could both add the same
#   minutes. Redeploy sla_get_spent, which now locks the issue's SLA cache
#   row before reading the stored total.

class SerializeSlaSpentCalculation < ActiveRecord::Migration[5.2]

  def up
    # MySQL has no CREATE OR REPLACE FUNCTION (see 202111112021015).
    execute "DROP FUNCTION IF EXISTS sla_get_spent ;" if RedmineSla::DbDialect.adapter == :mysql
    execute RedmineSla::DbDialect.function_sql('sla_get_spent')
    say "Redeployed function sla_get_spent"
  end

  def down
    # Nothing to restore: the locking function stays correct for earlier
    # schema versions.
  end

end
