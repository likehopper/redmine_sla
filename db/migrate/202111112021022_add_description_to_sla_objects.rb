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
# File: redmine_sla/db/migrate/202111112021022_add_description_to_sla_objects.rb
# Purpose:
#   Add an optional free-text `description` to the named SLA objects
#   (SLAs, SLA types, SLA calendars and SLA levels). Views render the wiki
#   source on detail pages and as plain-text tooltips in supported lists.
#   The column is nullable so existing rows and fixtures stay valid.

class AddDescriptionToSlaObjects < ActiveRecord::Migration[5.2]

  TABLES = %i[slas sla_types sla_calendars sla_levels].freeze

  def change
    TABLES.each do |table|
      add_column table, :description, :text
    end
  end

end
