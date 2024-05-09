class CreateSlaCacheSpents < ActiveRecord::Migration[5.2]

  def change

    reversible do |dir|
    
      dir.up do      

        create_table :sla_cache_spents do |t|
          t.belongs_to :sla_cache, :null => false, foreign_key: { name: 'sla_cache_spents_sla_caches_fkey', on_delete: :cascade }
          t.belongs_to :project, :null => false, foreign_key: { name: 'sla_caches_projects_fkey', on_delete: :cascade }
          t.belongs_to :issue, :null => false, foreign_key: { name: 'sla_cache_spents_issues_fkey', on_delete: :cascade }
          t.belongs_to :sla_type, :null => false, foreign_key: { name: 'sla_cache_spents_sla_types_fkey', on_delete: :cascade }
          t.integer :spent, :null => false
          t.datetime :updated_on, :null => false
        end
        say "Created table sla_cache_spents"

        add_index :sla_caches, [:project_id], :unique => false, name: 'sla_cache_spents_projects_key'
        add_index :sla_caches, [:issue_id], :unique => false, name: 'sla_cache_spents_issues_key'
        say "Created index on table sla_cache_spents"
        
        add_index :sla_cache_spents, [:sla_cache_id, :sla_type_id], :unique => true, name: 'sla_cache_spents_sla_caches_sla_types_ukey', \
          comment: "This index is an important constraint for update the cache on conflict instead insert"
        say "Created unique index on table sla_cache_spents"

        execute "ALTER TABLE sla_cache_spents ADD CONSTRAINT sla_cache_spents_sla_caches_sla_types_ukey UNIQUE USING INDEX sla_cache_spents_sla_caches_sla_types_ukey;"
        say "Created constraint on table sla_cache_spents"

        execute File.read(File.expand_path('../../sql_functions/sla_get_spent.sql', __FILE__))
        say "Created function sla_get_spent"

      end

      dir.down do
      
        execute <<-SQL
          DROP FUNCTION IF EXISTS sla_get_spent ;
        SQL
        say "Dropped function sla_get_spent"

        drop_table :sla_cache_spents
        say "Dropped table sla_cache_spent"

      end

    end

  end

end
