class CreateSlaCalendars < ActiveRecord::Migration[5.2]

  def change
    create_table :sla_calendars do |t|
      t.text :name, :null => false, index: { name: 'sla_calendars_name_ukey', unique: true }
      t.datetime :created_on, :null => false, default: -> { 'CURRENT_TIMESTAMP' }
      t.datetime :updated_on, :null => false, default: -> { 'CURRENT_TIMESTAMP' }      
    end
    say "Created table sla_calendars"
  end

end
