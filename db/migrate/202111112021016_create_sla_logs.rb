# File: redmine_sla/db/migrate/202111112021016_create_sla_logs.rb
# Purpose:
#   Create the `sla_logs` table and the PostgreSQL ENUM type `sla_log_level`.
#   This log table stores internal diagnostic and debugging entries produced
#   during SLA calculation or rule evaluation. Each log entry may reference:
#     - a project,
#     - an issue,
#     - an SLA level,
#     - a severity level (ENUM),
#     - and a textual description.
#
#   The migration ensures that the ENUM type is created only once, even if the
#   migration is run multiple times (e.g. when restoring a database).

class CreateSlaLogs < ActiveRecord::Migration[5.2]

  def change

    reversible do |dir|
    
      dir.up do

        # Create ENUM type only if it does not already exist
        execute <<~SQL
          DO $$
          BEGIN
            IF NOT EXISTS (
              SELECT 1 FROM pg_type WHERE typname = 'sla_log_level'
            ) THEN
              CREATE TYPE sla_log_level AS ENUM
                ('log_none', 'log_error', 'log_info', 'log_debug');
            END IF;
          END;
          $$;
        SQL
        say "Created enum sla_log_level"

        # Create diagnostic log table
        create_table :sla_logs do |t|

          # Optional links to project, issue and SLA level
          t.belongs_to :project,
                       null: true,
                       foreign_key: {
                         name: 'sla_logs_projects_fkey',
                         on_delete: :cascade
                       }

          t.belongs_to :issue,
                       null: true,
                       foreign_key: {
                         name: 'sla_logs_issues_fkey',
                         on_delete: :cascade
                       }

          t.belongs_to :sla_level,
                       null: true,
                       foreign_key: {
                         name: 'sla_logs_sla_levels_fkey',
                         on_delete: :cascade
                       }

          # Severity level based on the PostgreSQL ENUM
          t.column :log_level, :sla_log_level, null: false

          # Log message
          t.text :description, null: false
        end

        say "Created table sla_logs"

      end

      dir.down do

        # Drop log table first
        drop_table :sla_logs
        say "Dropped table sla_logs"

        # Then drop ENUM (only if exists)
        execute "DROP TYPE IF EXISTS sla_log_level;"
        say "Dropped enum sla_log_level"
        
      end 

    end

  end

end