class CreateSlaCaches < ActiveRecord::Migration[5.2]

  def change

    reversible do |dir|
    
      dir.up do    

        create_table :sla_caches do |t|
          t.belongs_to :issue, :null => false, foreign_key: { on_delete: :cascade }
          t.belongs_to :sla_level, :null => false, foreign_key: { on_delete: :cascade }
          t.datetime :start_date, :null => false
        end
        say "Created table sla_caches"

        add_index :sla_caches, [:issue_id ], :unique => true, name: 'sla_cache_issue_ukey'
        add_index :sla_caches, [:issue_id, :sla_level_id ], :unique => true, name: 'sla_cache_issue_level_ukey'
        say "Created index on table sla_caches"

        execute File.read(File.expand_path('../../sql_functions/sla_get_level.sql', __FILE__))
        say "Created function sla_get_level"

      end

      dir.down do
      
        execute <<-SQL
          DROP FUNCTION IF EXISTS sla_get_level ;
        SQL
        say "Dropped function sla_get_level"

        drop_table :sla_caches
        say "Dropped table sla_caches"     
        
      end

    end

  end

end
