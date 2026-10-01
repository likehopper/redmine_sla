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
# File: redmine_sla/db/migrate/202111112021012_create_sla_statuses.rb
# Purpose:
#   Create the `sla_statuses` table, which links Redmine issue statuses to SLA
#   types. This mapping is used to determine, for each status, how it should
#   behave from an SLA perspective (for example: count time, pause, stop, etc.,
#   depending on the associated SLA type).

class CreateSlaStatuses < ActiveRecord::Migration[5.2]

  def change
    create_table :sla_statuses do |t|

      # Reference to the Redmine issue status (from `issue_statuses` table).
      # type: :integer: issue_statuses predates Rails 5.1's bigint-by-default
      # primary keys and still uses an `int` id. PostgreSQL silently allows a
      # bigint foreign key to reference an int primary key, but MySQL/InnoDB
      # rejects the type mismatch outright, so the FK column must match
      # exactly.
      t.belongs_to :status,
        references: :IssueStatuses,
        type: :integer,
        foreign_key: {
          name: 'sla_statuses_issue_statuses_fkey',
          on_delete: :cascade,
          to_table: :issue_statuses
        }

      # Reference to the SLA type used to categorize the behavior of this status
      t.belongs_to :sla_type,
        foreign_key: {
          name: 'sla_statuses_sla_types_fkey',
          on_delete: :cascade
        }
    end

    # Migration log message (kept as-is, even if the wording mentions "sla_level_terms")
    say "Created table sla_level_terms"

    # Ensure that a given (status_id, sla_type_id) pair is unique
    add_index :sla_statuses,
              [:status_id, :sla_type_id],
              unique: true,
              name: 'sla_statuses_ukey'
    say "Created index unique sla_statuses_ukey"
  
  end

end