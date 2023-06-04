class CreateSlaLogs < ActiveRecord::Migration[5.2]

  def change

    reversible do |dir|
    
      dir.up do

        execute "CREATE TYPE sla_log_level AS ENUM ( 'log_none', 'log_error', 'log_info', 'log_debug' ) ; "
        say "Created enum sla_log_level"

        create_table :sla_logs do |t|
          t.belongs_to :project, null: true, foreign_key: { on_delete: :cascade }
          t.belongs_to :issue, null: true, foreign_key: { on_delete: :cascade }
          t.belongs_to :sla_level, null: true, foreign_key: { on_delete: :cascade }
          t.column :log_level, :sla_log_level, null: true
          t.text :description, null: true
        end
        say "Created table sla_logs"

      end

      dir.down do

        drop_table :sla_logs
        say "Dropped table sla_logs"

        execute "DROP TYPE sla_log_level ; "
        say "Dropped enum sla_log_level"
        
      end 

    end

  end

end
