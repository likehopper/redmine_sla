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
# File: redmine_sla/db/migrate/202111112021010_create_sla_project_trackers.rb
# Purpose:
#   Create the `sla_project_trackers` table, which links:
#     - a Redmine project,
#     - a Redmine tracker,
#     - a given SLA definition.
#
#   This association determines which SLA applies to issues of a specific
#   tracker inside a specific project. Each (project, tracker) pair must be
#   unique, ensuring that only one SLA is attached to the combination.

class CreateSlaProjectTrackers < ActiveRecord::Migration[5.2]

  def change
    create_table :sla_project_trackers do |t|

      # Link to the Redmine project.
      # type: :integer on the Redmine-core references below: those core
      # tables predate Rails 5.1's bigint-by-default primary keys and still
      # use `int` ids. PostgreSQL silently allows a bigint foreign key to
      # reference an int primary key, but MySQL/InnoDB rejects the type
      # mismatch outright, so the FK column must match exactly.
      t.belongs_to :project,
                   type: :integer,
                   foreign_key: {
                     name: 'sla_project_trackers_projects_fkey',
                     on_delete: :cascade
                   }

      # Link to the Redmine tracker
      t.belongs_to :tracker,
                   type: :integer,
                   foreign_key: {
                     name: 'sla_project_trackers_trackers_fkey',
                     on_delete: :cascade
                   }

      # Link to the SLA definition applied to this (project, tracker) pair
      t.belongs_to :sla,
                   foreign_key: {
                     name: 'sla_project_trackers_slas_fkey',
                     on_delete: :cascade
                   }
    end

    # Migration log message
    say "Created table sla_project_trackers"
    
    # Ensure that a project cannot define more than one SLA for the same tracker
    add_index :sla_project_trackers,
              [:project_id, :tracker_id],
              unique: true,
              name: 'sla_project_trackers_ukey'
    say "Created index unique sla_project_trackers_ukey"

  end

end