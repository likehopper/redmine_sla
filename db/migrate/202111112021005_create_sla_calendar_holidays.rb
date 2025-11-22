# File: redmine_sla/db/migrate/202111112021005_create_sla_calendar_holidays.rb
# Purpose:
#   Create the join table `sla_calendar_holidays`, which associates holidays
#   with SLA calendars. This defines which holidays apply to which calendars,
#   and whether a holiday is considered as matching (SLA active) or non-matching
#   (SLA paused) in calendar calculations.

class CreateSlaCalendarHolidays < ActiveRecord::Migration[5.2]

  def change
    create_table :sla_calendar_holidays do |t|

      # Link to the SLA calendar
      t.integer :sla_calendar_id, null: false

      # Link to the holiday definition
      t.integer :sla_holiday_id, null: false

      # Whether the holiday is considered as a matching day
      # (true = SLA counts time on this holiday, false = SLA stops)
      t.boolean :match, null: false, default: false
    end

    # Index to ensure that a holiday is not assigned twice to the same calendar
    add_index :sla_calendar_holidays,
              [:sla_calendar_id, :sla_holiday_id],
              unique: true,
              name: 'sla_calendar_holiday_ukey'

    # Migration log entry
    say "Created table sla_calendar_holidays with unique index sla_calendar_holiday_ukey"
  end

end