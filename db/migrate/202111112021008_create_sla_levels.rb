class CreateSlaLevels < ActiveRecord::Migration[5.2]

  def change
    create_table :sla_levels do |t|
      t.text :name, :null => false, index: { name: 'sla_levels_name_ukey', unique: true }
      t.belongs_to :sla, foreign_key: { name: 'sla_levels_slas_fkey', on_delete: :cascade }
      t.belongs_to :sla_calendar, foreign_key: { name: 'sla_levels_sla_calendars_fkey', on_delete: :cascade }    
    end
    say "Created table sla_levels"

  end

end
