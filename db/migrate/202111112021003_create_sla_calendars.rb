# File: redmine_sla/db/migrate/202111112021003_create_sla_calendars.rb
# Purpose:
#   Create the `sla_calendars` table, which stores SLA calendar definitions.
#   An SLA calendar defines the weekly time windows where SLA time can elapse.
#   Each calendar can be associated with multiple SLA schedules and levels.

class CreateSlaCalendars < ActiveRecord::Migration[5.2]

  def change
    create_table :sla_calendars do |t|

      # Calendar name, must be unique across all calendars
      t.text :name, null: false, index: { name: 'sla_calendars_name_ukey', unique: true }

      # Standard timestamp fields used across the plugin
      t.datetime :created_on, null: false, default: -> { 'CURRENT_TIMESTAMP' }
      t.datetime :updated_on, null: false, default: -> { 'CURRENT_TIMESTAMP' }
    end

    # Rails migration log output
    say "Created table sla_calendars"
  end

end