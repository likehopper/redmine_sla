# frozen_string_literal: true

# File: redmine_sla/test/documentation/modules/05_sla_holidays_module.rb
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

module SlaHolidaysDocumentationTest

  def test_05_sla_holiday
    id = 5

    sla_holidays = fixture!('sla_holidays') 

    log_user('admin', 'admin') if sla_holidays.any?

    sla_holidays.each.with_index(1) do |sla_holiday, idx|
      sla_holiday_name     = sla_holiday.fetch('name')
      sla_holiday_date     = Date.parse(sla_holiday.fetch('date').to_s)

      visit '/sla/holidays/new'
      fill_in 'sla_holiday_name', with: sla_holiday_name
      fill_in 'sla_holiday_date', with: format_date(sla_holiday_date)

      take_doc_screenshot(format("%02d-01-%02d-01-sla_holiday-new.png", id, idx)) if idx==1
      click_button l("sla_label.sla_holiday.new")

      sla_holiday = SlaHoliday.find_by!(
        name: sla_holiday_name,
        date: sla_holiday_date,
      )
      
      assert_text(l('sla_label.sla_holiday.notice_successful_create', id: "##{sla_holiday.id}"))
      take_doc_screenshot(format("%02d-01-%02d-02-sla_holiday-created.png", id, idx)) if idx==1
      
    end

    take_doc_screenshot(format("%02d-02-sla_holiday-list.png", id)) if sla_holidays.any?

  end
end