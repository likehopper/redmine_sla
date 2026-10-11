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
# File: redmine_sla/db/migrate/202111112021021_gate_sla_get_level_on_project_module.rb
# Purpose:
#   Stop SLA calculation for projects whose SLA module is disabled, while
#   keeping their SLA configuration (sla_project_trackers):
#     - redeploy sla_get_level, which now returns NULL for such projects
#       (sla_get_spent goes through it),
#     - purge the cache left behind by modules disabled before this upgrade.

class GateSlaGetLevelOnProjectModule < ActiveRecord::Migration[5.2]

  def up
    # MySQL has no CREATE OR REPLACE FUNCTION (see 202111112021014).
    execute "DROP FUNCTION IF EXISTS sla_get_level ;" if RedmineSla::DbDialect.adapter == :mysql
    execute RedmineSla::DbDialect.function_sql('sla_get_level')
    say "Redeployed function sla_get_level"

    # sla_cache_spents are removed by the database foreign key cascade.
    execute <<~SQL
      DELETE FROM sla_caches
      WHERE project_id NOT IN (
        SELECT project_id FROM enabled_modules WHERE name = 'sla'
      )
    SQL
    say "Purged SLA cache of projects without the SLA module"
  end

  def down
    # Nothing to restore: the purged cache is recomputable, and the gated
    # sla_get_level stays correct for earlier schema versions. Rolling back
    # further (VERSION=0) drops the function in 202111112021014.
  end

end
