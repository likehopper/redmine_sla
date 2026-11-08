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
# File: redmine_sla/db/migrate/202111112021027_order_sla_level_ties.rb
# Purpose:
#   sla_get_level picked the first matching (level, schedule) by opening
#   minute only. When two levels of one SLA open at the same minute, the
#   database could return either one. Redeploy sla_get_level with the level
#   id as tie-breaker. Existing caches are kept.

class OrderSlaLevelTies < ActiveRecord::Migration[5.2]

  def up
    # MySQL has no CREATE OR REPLACE FUNCTION (see 202111112021014).
    execute "DROP FUNCTION IF EXISTS sla_get_level ;" if RedmineSla::DbDialect.adapter == :mysql
    execute RedmineSla::DbDialect.function_sql('sla_get_level')
    say "Redeployed function sla_get_level"
  end

  def down
    # Nothing to restore: the deterministic order stays correct for earlier
    # schema versions.
  end

end
