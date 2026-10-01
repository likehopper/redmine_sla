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
# File: redmine_sla/db/migrate/202111112021007_create_sla_types.rb
# Purpose:
#   Create the `sla_types` table, which stores the different SLA categories/types.
#   These types can be used to group SLAs (e.g. "Response time", "Resolution time")
#   and may be referenced by other SLA-related entities.

class CreateSlaTypes < ActiveRecord::Migration[5.2]

  def change
    create_table :sla_types do |t|

      # SLA type name, must be unique across all SLA types
      # (string rather than text: MySQL/MariaDB cannot put a unique index on
      # a full TEXT column without a key-length prefix)
      t.string :name, limit: 255, null: false,
                    index: { name: 'sla_types_name_ukey', unique: true }
    end

    # Migration log output
    say "Created table sla_types"
  end

end