class CreateSlaCacheSpents < ActiveRecord::Migration[5.2]

  def change

    reversible do |dir|
    
      dir.up do      

        create_table :sla_cache_spents, id: false, force: :cascade do |t|
          t.belongs_to :sla_cache, :null => false, foreign_key: { on_delete: :cascade }
          t.belongs_to :sla_type, :null => false, foreign_key: { on_delete: :cascade }
          #t.belongs_to :issue, :null => false, foreign_key: { on_delete: :cascade }
          #t.integer :priority_id, :null => false
          #t.integer :term, :null => false
          t.datetime :updated_on, :null => false
          t.integer :spent, :null => false
        end
        say "Created table sla_cache_spent"

        # without issue
        execute "ALTER TABLE sla_cache_spents ADD PRIMARY KEY ( sla_cache_id, sla_type_id ) ; "

        # With issue
        #execute "ALTER TABLE sla_cache_spents ADD PRIMARY KEY ( issue_id, sla_type_id ) ; "
        #add_index :sla_cache_spents, [:sla_cache_id, :sla_type_id ], :unique => true, name: 'sla_cache_cache_type_ukey'
        #add_index :sla_cache_spents, [:issue_id, :sla_type_id ], :unique => true, name: 'sla_cache_issue_type_ukey'

        say "Created index on table sla_cache_spent"

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
