# frozen_string_literal: true

# File: redmine_sla/test/documentation/modules/06_sla_calendar_holidays_module.rb
# Redmine SLA - Redmine's Plugin 
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

module SlaCalendarHolidaysDocumentationTest

  def test_06_sla_calendar_holiday
    id=6

    sla_calendar_holidays = fixture!('sla_calendar_holidays')

    log_user('admin', 'admin') if sla_calendar_holidays.any?

    sla_calendar_holidays.each.with_index(1) do |sla_calendar_holiday, idx|

      # Resolve names -> records
      sla_calendar_name = sla_calendar_holiday.fetch('sla_calendar')
      sla_holiday_name  = sla_calendar_holiday.fetch('sla_holiday')
      match             = sla_calendar_holiday.fetch('match')

      visit '/sla/calendar_holidays/new'

      # Resolve names -> records
      sla_calendar = SlaCalendar.find_by!(name: sla_calendar_name)
      sla_holiday = SlaHoliday.find_by!(name: sla_holiday_name)
      
      # Select by id
      find('#sla_calendar_holiday_sla_calendar_id').find("option[value='#{sla_calendar.id}']").select_option
      find('#sla_calendar_holiday_sla_holiday_id').find("option[value='#{sla_holiday.id}']").select_option

      # Match checkbox (boolean)
      if match
        check 'sla_calendar_holiday_match'
      else
        uncheck 'sla_calendar_holiday_match' rescue nil
      end      

      # Take the photo and submit the form
      take_doc_screenshot(format("%02d-01-%02d-01-sla_calendar_holiday-new.png", id, idx)) if idx==1
      click_button l("sla_label.sla_calendar_holiday.new")

      # Search for the record
      sla_calendar_holiday = SlaCalendarHoliday.find_by!(
        sla_calendar_id: sla_calendar.id,
        sla_holiday_id: sla_holiday.id,
      )      

      # Validation and screenshot
      assert_text(l(:notice_successful_create))
      take_doc_screenshot(format("%02d-01-%02d-02-sla_calendar_holiday-created.png", id, idx)) if idx==1

    end

    take_doc_screenshot(format("%02d-02-sla_calendar_holiday-list.png", id)) if sla_calendar_holidays.any?

  end
end