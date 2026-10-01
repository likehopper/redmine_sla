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
# File: redmine_sla/db/migrate/202111112021020_add_position_to_sla_types.rb
# Purpose:
#   Add a `position` column to `sla_types`, giving admins control over the
#   display order of SLA types wherever they appear as columns (issue view
#   gauges, issue/time-entry list columns, the SLA level terms matrix)
#   instead of the incidental creation order they've had until now.

class AddPositionToSlaTypes < ActiveRecord::Migration[5.2]

  def up
    add_column :sla_types, :position, :integer

    # Plugin models aren't safely loadable from a migration. Keep this
    # adapter-independent as Redmine supports PostgreSQL, MySQL/MariaDB and
    # SQLite, and SLA types are a small administration list.
    select_values("SELECT id FROM sla_types ORDER BY id").each_with_index do |id, index|
      execute "UPDATE sla_types SET position = #{index + 1} WHERE id = #{connection.quote(id)}"
    end

    change_column_null :sla_types, :position, false

    say "Added and backfilled sla_types.position"
  end

  def down
    remove_column :sla_types, :position
  end

end
