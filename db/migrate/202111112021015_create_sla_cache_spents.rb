# File: redmine_sla/db/migrate/202111112021015_create_sla_cache_spents.rb
# Purpose:
#   Create the `sla_cache_spents` table, which stores precomputed SLA time
#   consumption (“spent” minutes) per issue and SLA type. This acts as a cache
#   on top of `sla_caches` to avoid recalculating SLA minutes each time.
#   The migration also loads the SQL function `sla_get_spent` used to compute
#   and refresh these values.

class CreateSlaCacheSpents < ActiveRecord::Migration[5.2]

  def change

    reversible do |dir|
    
      dir.up do      

        # Main cache table storing spent SLA minutes per (sla_cache, sla_type)
        create_table :sla_cache_spents do |t|

          # Link to the main SLA cache entry for this issue
          t.belongs_to :sla_cache, null: false,
                                   foreign_key: {
                                     name: 'sla_cache_spents_sla_caches_fkey',
                                     on_delete: :cascade
                                   }

          # Redmine project associated with the issue.
          # type: :integer on the Redmine-core references below: those core
          # tables predate Rails 5.1's bigint-by-default primary keys and
          # still use `int` ids. PostgreSQL silently allows a bigint foreign
          # key to reference an int primary key, but MySQL/InnoDB rejects the
          # type mismatch outright, so the FK column must match exactly.
          t.belongs_to :project, null: false, type: :integer,
                                 foreign_key: {
                                   name: 'sla_cache_spents_projects_fkey',
                                   on_delete: :cascade
                                 }

          # Redmine issue itself
          t.belongs_to :issue, null: false, type: :integer,
                               foreign_key: {
                                 name: 'sla_cache_spents_issues_fkey',
                                 on_delete: :cascade
                               }

          # SLA type (e.g. Resolution, Response, etc.)
          t.belongs_to :sla_type, null: false,
                                  foreign_key: {
                                    name: 'sla_cache_spents_sla_types_fkey',
                                    on_delete: :cascade
                                  }

          # Spent time in minutes for this SLA type
          t.integer :spent, null: false

          # Technical timestamps
          t.datetime :created_on, null: false, default: -> { 'CURRENT_TIMESTAMP' }
          t.datetime :updated_on, null: false, default: -> { 'CURRENT_TIMESTAMP' }
        end
        say "Created table sla_cache_spents"

        # Non-unique indexes on project and issue for reporting/filtering
        add_index :sla_cache_spents, [:project_id],
                  unique: false,
                  name: 'sla_cache_spents_projects_key'
        add_index :sla_cache_spents, [:issue_id],
                  unique: false,
                  name: 'sla_cache_spents_issues_key'
        say "Created index on table sla_cache_spents"
        
        # This unique index is required to support "upsert" logic (update on conflict)
        # per (sla_cache_id, sla_type_id) combination.
        add_index :sla_cache_spents,
                  [:sla_cache_id, :sla_type_id],
                  unique: true,
                  name: 'sla_cache_spents_sla_caches_sla_types_ukey'
        say "Created unique index on table sla_cache_spents"

        # Add constraint bound to the previously created unique index.
        # PostgreSQL-only: MySQL's sla_get_spent.sql uses ON DUPLICATE KEY
        # UPDATE, which works off the unique index created above directly
        # and has no equivalent of naming a constraint from an index.
        if RedmineSla::DbDialect.adapter == :postgresql
          execute <<~SQL
            ALTER TABLE sla_cache_spents
            ADD CONSTRAINT sla_cache_spents_sla_caches_sla_types_ukey
            UNIQUE USING INDEX sla_cache_spents_sla_caches_sla_types_ukey;
          SQL
          say "Created constraint on table sla_cache_spents"
        end

        # Load the function used to calculate SLA spent time.
        # MySQL has no CREATE OR REPLACE FUNCTION (unlike PostgreSQL, whose
        # file already self-contains an equivalent DROP), and Rails' mysql2
        # driver doesn't support multiple statements in a single execute call,
        # so the drop is issued separately here.
        execute "DROP FUNCTION IF EXISTS sla_get_spent ;" if RedmineSla::DbDialect.adapter == :mysql
        execute RedmineSla::DbDialect.function_sql('sla_get_spent')
        say "Created function sla_get_spent"

      end

      dir.down do
      
        # Drop the calculation function on rollback
        execute <<-SQL
          DROP FUNCTION IF EXISTS sla_get_spent ;
        SQL
        say "Dropped function sla_get_spent"

        # Drop the cache table
        drop_table :sla_cache_spents
        say "Dropped table sla_cache_spent"

      end

    end

  end

end