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

      # Link to the Redmine project
      t.belongs_to :project,
                   foreign_key: {
                     name: 'sla_project_trackers_projects_fkey',
                     on_delete: :cascade
                   }

      # Link to the Redmine tracker
      t.belongs_to :tracker,
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