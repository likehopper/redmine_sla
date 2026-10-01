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
# File: redmine_sla/db/migrate/202111112021001_create_slas.rb
# Purpose:
#   Define the base "slas" table, which stores the main SLA entities used
#   by the plugin (name and unique constraint). Other SLA-related tables
#   reference this one.

class CreateSlas < ActiveRecord::Migration[5.2]

  def change
    create_table :slas do |t|
      # SLA display name, required and unique across all SLAs
      # (string rather than text: MySQL/MariaDB cannot put a unique index on
      # a full TEXT column without a key-length prefix)
      t.string :name, limit: 255, null: false, index: { name: 'slas_name_ukey', unique: true }
    end

    # Migration log message shown when the table is created
    say "Created table slas"
  end

end