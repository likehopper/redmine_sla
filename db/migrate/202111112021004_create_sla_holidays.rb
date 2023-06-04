class CreateSlaHolidays < ActiveRecord::Migration[5.2]

  def change
    create_table :sla_holidays do |t|
      t.date :date, :null => false, index: { unique: true }
      t.text :name, :null => false
    end
    say "Created table sla_holidays"
  end

end