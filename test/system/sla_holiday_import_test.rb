# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

# File: redmine_sla/test/system/sla_holiday_import_test.rb
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

require_relative '../application_sla_system_test_case'

class SlaHolidayImportSystemTest < ApplicationSlaSystemTestCase
  test 'administrator previews and imports selected holidays in the browser' do
    SlaHolidayAdapters::NagerDate.any_instance.stubs(:available_countries).returns([['France', 'FR']])
    SlaHolidayAdapters::NagerDate.any_instance.stubs(:holidays).returns([
      { 'date' => '2098-01-01', 'name' => 'National test holiday', 'national' => true, 'regions' => [] },
      { 'date' => '2098-01-02', 'name' => 'Regional test holiday', 'national' => false, 'regions' => ['FR-67'] }
    ])
    log_user('admin', 'admin')
    visit '/sla/holidays'
    click_link l(:sla_holiday_import_title)
    fill_in 'year', with: '2098'
    select 'France', from: 'country'
    click_button l(:label_preview)
    assert_text 'National test holiday 2098'
    assert_text 'FR-67'
    assert_checked_field 'holiday_0'
    assert_unchecked_field 'holiday_1'
    assert_nil SlaHoliday.find_by(date: '2098-01-01')
    click_button l(:button_import)
    assert_current_path '/sla/holidays'
    assert_selector '#flash_notice'
    assert_equal 'National test holiday 2098', SlaHoliday.find_by(date: '2098-01-01').name
    assert_nil SlaHoliday.find_by(date: '2098-01-02')
  end

  test 'API unavailable leaves form usable for retry without import' do
    SlaHolidayAdapters::NagerDate.any_instance.stubs(:available_countries).raises(SlaHolidayAdapters::NagerDate::Error, 'unavailable')
    log_user('admin', 'admin')
    visit '/sla/holidays/import'
    assert_selector '#flash_error'
    assert_button l(:label_preview), disabled: true
    assert_no_selector 'input[name=preview_token]'
  end
end
