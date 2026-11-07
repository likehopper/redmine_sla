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
# File: redmine_sla/db/migrate/202111112021026_parse_all_sla_time_zones.rb
# Purpose:
#   sla_get_date read the configured time zone with a pattern limited to
#   letters and "/": America/New_York was read as America/New, and
#   Etc/GMT+12 as Etc/GMT. Redeploy sla_get_date with a pattern covering
#   every IANA zone name. Existing caches are not recalculated.

class ParseAllSlaTimeZones < ActiveRecord::Migration[5.2]

  def up
    # PostgreSQL replaces the function in place, keeping its dependent views.
    # MySQL has no CREATE OR REPLACE FUNCTION (see 202111112021015).
    execute "DROP FUNCTION IF EXISTS sla_get_date ;" if RedmineSla::DbDialect.adapter == :mysql
    execute RedmineSla::DbDialect.function_sql('sla_get_date')
    say "Redeployed function sla_get_date"
  end

  def down
    # Nothing to restore: the wider pattern stays correct for earlier schema
    # versions.
  end

end
