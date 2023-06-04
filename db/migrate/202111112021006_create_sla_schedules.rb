class CreateSlaSchedules < ActiveRecord::Migration[5.2]

  def change
    create_table :sla_schedules do |t|
      t.belongs_to :sla_calendar, foreign_key: { on_delete: :cascade }
      t.integer :dow, :null => false
      t.time :start_time, :null => false
      t.time :end_time, :null => false
      t.boolean :match, :null => false
    end
    say "Created table sla_schedules"

    add_index :sla_schedules, [:sla_calendar_id, :dow, :start_time, :end_time ], :unique => true, name: 'sla_schedules_ukey'
    say "Created index unique sla_schedules_ukey"

  end

end
