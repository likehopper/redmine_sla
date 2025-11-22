# File: redmine_sla/db/migrate/202111112021014_create_sla_caches.rb
# Purpose:
#   Create the `sla_caches` table, which stores precomputed SLA level data
#   for each issue. This table acts as a cache to speed up SLA evaluation,
#   avoiding repeated computation of SLA levels. It includes:
#     - the detected SLA level for the issue,
#     - start date of the SLA countdown,
#     - timestamps for updates,
#     - functions used to calculate SLA levels and detect overlaps.
#
#   This migration also loads the SQL functions:
#     - sla_get_level_overlap
#     - sla_get_level

class CreateSlaCaches < ActiveRecord::Migration[5.2]

  def change

    reversible do |dir|
    
      dir.up do    

        # Main table creation (id is manually controlled, not auto-incremented)
        create_table :sla_caches, id: false do |t|
          t.bigint :id, null: false

          # Associations
          t.belongs_to :project, null: false,
                                 foreign_key: {
                                   name: 'sla_caches_projects_fkey',
                                   on_delete: :cascade
                                 }

          t.belongs_to :issue, null: false,
                               foreign_key: {
                                 name: 'sla_caches_issues_fkey',
                                 on_delete: :cascade
                               }

          t.belongs_to :tracker, null: false,
                                 foreign_key: {
                                   name: 'sla_caches_trackers_fkey',
                                   on_delete: :cascade
                                 }

          t.belongs_to :sla_level, null: false,
                                   foreign_key: {
                                     name: 'sla_caches_sla_levels_fkey',
                                     on_delete: :cascade
                                   }

          # SLA start date and technical timestamps
          t.datetime :start_date, null: false
          t.datetime :created_on, null: false, default: -> { 'CURRENT_TIMESTAMP' }
          t.datetime :updated_on, null: false, default: -> { 'CURRENT_TIMESTAMP' }
        end
        say "Created table sla_caches"

        # Add explicit primary key
        execute "ALTER TABLE sla_caches ADD PRIMARY KEY (id) ; "

        # Non-unique index for project filtering
        add_index :sla_caches, [:project_id],
                  unique: false,
                  name: 'sla_caches_projects_key'
        say "Created index on table sla_caches"

        # Unique index for issue-based lookup (each issue has exactly one SLA cache)
        add_index :sla_caches, [:issue_id],
                  unique: true,
                  name: 'sla_caches_issues_ukey'
        say "Created unique index on table sla_caches"

        # Constraint ensuring ON CONFLICT updates use the unique index
        execute <<~SQL
          ALTER TABLE sla_caches
          ADD CONSTRAINT sla_caches_issues_ukey
          UNIQUE USING INDEX sla_caches_issues_ukey;
        SQL
        say "Created constraints on table sla_caches"

        # Load supporting SQL functions
        execute File.read(
          File.expand_path('../../sql_functions/sla_get_level_overlap.sql', __FILE__)
        )
        say "Created function sla_get_level_overlap"

        execute File.read(
          File.expand_path('../../sql_functions/sla_get_level.sql', __FILE__)
        )
        say "Created function sla_get_level"

      end

      dir.down do
        
        # Remove SLA functions
        execute <<-SQL
          DROP FUNCTION IF EXISTS sla_get_level ;
        SQL
        say "Dropped function sla_get_level"

        # Drop table
        drop_table :sla_caches
        say "Dropped table sla_caches"
        
      end

    end

  end

end