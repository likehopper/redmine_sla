class CreateSlaLevels < ActiveRecord::Migration[5.2]

  def change
    create_table :sla_levels do |t|
      t.text :name, :null => false, index: { unique: true }
      t.belongs_to :sla, foreign_key: { on_delete: :cascade }
      t.belongs_to :sla_calendar, foreign_key: { on_delete: :cascade }    
    end
    say "Created table sla_levels"

  end

end
