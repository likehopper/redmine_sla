class CreateSlaCalendars < ActiveRecord::Migration[5.2]

  def change
    create_table :sla_calendars do |t|
      t.text :name, :null => false, index: { unique: true }
    end
    say "Created table sla_calendars"
  end

end
