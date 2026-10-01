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
# File: redmine_sla/db/migrate/202111112021006_create_sla_schedules.rb
# Purpose:
#   Create the `sla_schedules` table, which defines daily schedules for SLA
#   calendars. A schedule specifies on which weekday (0–6) and during which
#   time range the SLA is active. These schedules are later matched against
#   issue timestamps to determine whether SLA time should accumulate.

class CreateSlaSchedules < ActiveRecord::Migration[5.2]

  def change
    create_table :sla_schedules do |t|

      # Reference to the parent SLA calendar
      t.integer :sla_calendar_id, null: false

      # Day of the week: 0 = Sunday, 1 = Monday, ... 6 = Saturday
      t.integer :dow, null: false

      # Start and end times for the active SLA window during the specified weekday
      t.time :start_time, null: false
      t.time :end_time, null: false

      # Whether this schedule should be considered a match (true) or not (false)
      # Used to handle exceptional schedules or overrides
      t.boolean :match, null: false, default: true
    end

    # Migration log output
    say "Created table sla_schedules"
  end

end