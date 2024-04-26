class CreateSlaHolidays < ActiveRecord::Migration[5.2]

  def change
    create_table :sla_holidays do |t|
      t.date :date, :null => false, index: { name: 'sla_holidays_date_ukey', unique: true }
      t.text :name, :null => false
    end
    say "Created table sla_holidays"
  end

end