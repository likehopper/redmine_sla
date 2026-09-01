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

          # Associations.
          # type: :integer on the Redmine-core references below: those core
          # tables predate Rails 5.1's bigint-by-default primary keys and
          # still use `int` ids. PostgreSQL silently allows a bigint foreign
          # key to reference an int primary key, but MySQL/InnoDB rejects the
          # type mismatch outright, so the FK column must match exactly.
          t.belongs_to :project, null: false, type: :integer,
                                 foreign_key: {
                                   name: 'sla_caches_projects_fkey',
                                   on_delete: :cascade
                                 }

          t.belongs_to :issue, null: false, type: :integer,
                               foreign_key: {
                                 name: 'sla_caches_issues_fkey',
                                 on_delete: :cascade
                               }

          t.belongs_to :tracker, null: false, type: :integer,
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

        # Constraint ensuring ON CONFLICT updates use the unique index.
        # PostgreSQL-only: MySQL's sla_get_level.sql uses ON DUPLICATE KEY
        # UPDATE, which works off the unique index created above directly
        # and has no equivalent of naming a constraint from an index.
        if RedmineSla::DbDialect.adapter == :postgresql
          execute <<~SQL
            ALTER TABLE sla_caches
            ADD CONSTRAINT sla_caches_issues_ukey
            UNIQUE USING INDEX sla_caches_issues_ukey;
          SQL
          say "Created constraints on table sla_caches"
        end

        # Load supporting SQL functions.
        # MySQL has no CREATE OR REPLACE FUNCTION (unlike PostgreSQL, whose
        # files already self-contain an equivalent DROP), and Rails' mysql2
        # driver doesn't support multiple statements in a single execute call,
        # so the drops are issued separately here.
        if RedmineSla::DbDialect.adapter == :mysql
          execute "DROP FUNCTION IF EXISTS sla_get_level_overlap ;"
        end
        execute RedmineSla::DbDialect.function_sql('sla_get_level_overlap')
        say "Created function sla_get_level_overlap"

        execute "DROP FUNCTION IF EXISTS sla_get_level ;" if RedmineSla::DbDialect.adapter == :mysql
        execute RedmineSla::DbDialect.function_sql('sla_get_level')
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