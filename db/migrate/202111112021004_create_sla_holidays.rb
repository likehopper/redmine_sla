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
# File: redmine_sla/db/migrate/202111112021004_create_sla_holidays.rb
# Purpose:
#   Create the `sla_holidays` table, which stores individual holiday definitions
#   used by SLA calendars. A holiday has a date and a name, and may later be
#   linked to SLA calendars to determine whether SLA time is active or paused
#   on that specific day.

class CreateSlaHolidays < ActiveRecord::Migration[5.2]

  def change
    create_table :sla_holidays do |t|

      # Holiday date, must be unique across all entries
      t.date :date, null: false,
                    index: { name: 'sla_holidays_date_ukey', unique: true }

      # Human-readable holiday name (e.g. "Christmas", "New Year")
      t.text :name, null: false
    end

    # Migration log output
    say "Created table sla_holidays"
  end

end