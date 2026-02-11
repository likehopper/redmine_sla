# frozen_string_literal: true

# File: redmine_sla/test/documentation/modules/04_sla_calendar_module.rb
# Redmine SLA - Redmine plugin
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

module SlaCalendarsDocumentationTest

  # Clicks "Add Schedule", targets the LAST generated schedule row (dynamic timestamp in IDs),
  # then fills Day of Week, Start time, End time and Match.
  #
  # IMPORTANT:
  # - The time inputs are HTML5 `input[type="time"]`.
  # - Selenium/Chrome can display a value while the field is still invalid (you saw the "--" suffix).
  # - To keep tests stable, we always set the value via JS in the strict "HH:MM:SS" format and
  #   dispatch input/change events so the browser considers the field valid.
  def add_sla_schedule_row(dow:, start_time:, end_time:, match: true)
    click_link 'Add Schedule'

    dow_select  = all('select[id^="sla_calendar_sla_schedules_attributes_"][id$="_dow"]').last
    start_input = all('input[id^="sla_calendar_sla_schedules_attributes_"][id$="_start_time"]').last
    end_input   = all('input[id^="sla_calendar_sla_schedules_attributes_"][id$="_end_time"]').last
    match_input = all('input[id^="sla_calendar_sla_schedules_attributes_"][id$="_match"]').last

    dow_select.select(dow)

    set_time_input(start_input, start_time)
    set_time_input(end_input, end_time)

    match_input.set(match ? true : false)
  end

  # Sets an HTML5 time input in a browser-stable way.
  # `value_hhmm` must be "HH:MM" (e.g., "09:30"). We force seconds to ":00".
  def set_time_input(input, value_hhmm)
    page.execute_script(<<~JS)
      const el = document.getElementById("#{input[:id]}");
      if (!el) return;
      el.value = "#{value_hhmm}:00";
      el.dispatchEvent(new Event('input', { bubbles: true }));
      el.dispatchEvent(new Event('change', { bubbles: true }));
    JS
  end

  def test_04_sla_calendar
    id = 4

    sla_calendars = fixture!('sla_calendars') 

    # 1) Login as admin
    log_user('admin', 'admin') if sla_calendars.any?

    sla_calendars.each.with_index(1) do |row, idx|
      sla_calendar_name = row.fetch('name')
      sla_schedules = row.fetch('sla_schedules', [])
      
      visit '/sla/calendars/new'

      fill_in 'sla_calendar_name', with: sla_calendar_name

      # 2) Add all schedule rows before submitting the form
      sla_schedules.each do |dow, ranges|
        ranges.each do |start_time, end_time, match|
          add_sla_schedule_row(
            dow: dow,
            start_time: start_time,
            end_time: end_time,
            match: match
          )
        end
      end

      take_doc_screenshot(format('%02d-01-%02d-01-sla_calendar-new.png', id, idx))
      click_button l("sla_label.sla_calendar.new")

      sla_calendar = SlaCalendar.find_by(name: sla_calendar_name)

      assert_text(l('sla_label.sla_calendar.notice_successful_create', id: "##{sla_calendar.id}"))
      take_doc_screenshot(format("%02d-01-%02d-02-sla_calendar-created.png", id, idx))

    end

    # take_doc_screenshot(format('%02d-02-sla_calendar-list.png', id)) if sla_calendars.any?

  end
end