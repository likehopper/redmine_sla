class CreateSlaProjectTrackers < ActiveRecord::Migration[5.2]

  def change
    create_table :sla_project_trackers do |t|
      t.belongs_to :project, foreign_key: { on_delete: :cascade }
      t.belongs_to :tracker, foreign_key: { on_delete: :cascade }
      t.belongs_to :sla, foreign_key: { on_delete: :cascade }
    end
    say "Created table sla_project_trackers"
    
    add_index :sla_project_trackers, [:project_id, :tracker_id ], :unique => true, name: 'sla_project_trackers_ukey'
    say "Created index unique sla_project_trackers_ukey"

  end

end
