# frozen_string_literal: true

# File: redmine_sla/test/system/sla_holidays_helper.rb
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

require_relative "../application_sla_system_test_case"

class SlaHolidaysHelperSystemTest < ApplicationSlaSystemTestCase

  test "contextual_menu_sla_holiday" do
    sla_holiday = SlaHoliday.find(1)

    log_user('admin', 'admin')

    visit '/sla/holidays?sort=id'
    assert_text l('sla_label.sla_holiday.index')
    element = find('tr#entity_id_1')
    element.right_click
    assert_selector 'div#context-menu', visible: true
    assert_selector 'div#context-menu a', text: 'Show'
    find('div#context-menu a', text: l(:button_show)).click
    assert_current_path sla_holiday_path(sla_holiday)
    assert_text l('sla_label.sla_holiday.show')
    assert_text sla_holiday.name

    visit '/sla/holidays?sort=id'
    assert_text l('sla_label.sla_holiday.index')
    element = find('tr#entity_id_1')
    element.right_click
    assert_selector 'div#context-menu', visible: true
    assert_selector 'div#context-menu a', text: l(:button_edit)
    find('div#context-menu a', text: l(:button_edit)).click
    assert_current_path edit_sla_holiday_path(sla_holiday)
    assert_text l('sla_label.sla_holiday.edit')
    assert_field 'sla_holiday_name', with: sla_holiday.name

    visit '/sla/holidays?sort=id'
    assert_text l('sla_label.sla_holiday.index')
    element = find('tr#entity_id_1')
    element.right_click
    assert_selector 'div#context-menu', visible: true
    assert_selector 'div#context-menu a', text: l(:button_delete)
    accept_confirm do
      find('div#context-menu a', text: l(:button_delete)).click
    end
    assert_current_path sla_holidays_path(sort: :id)
    assert_text l(:notice_successful_delete)
    
  end 

  test "create_sla_holiday" do
    sla_holiday_name = 'new SLA Holiday'
    sla_holiday_date = '31/01/2025'

    log_user('admin', 'admin')

    visit '/sla/holidays/new'
    within('form#sla-holiday-form') do
      fill_in 'sla_holiday_name', :with => sla_holiday_name
      fill_in 'sla_holiday_date', :with => sla_holiday_date
      find('input[name=commit]').click
    end

    # find created issue
    sla_holiday = SlaHoliday.find_by_name(sla_holiday_name)
    assert_kind_of SlaHoliday, sla_holiday

    # check redirection
    find 'div#flash_notice',
      :visible => true,
      :text => l("sla_label.sla_holiday.notice_successful_create", :id => "##{sla_holiday.id}" )
    assert_equal sla_holidays_path, current_path

    # TODO : vérifier SlaHoliday#show
    # visit "/sla/holidayes/#{sla_holiday.id}"
    # compate sla_holiday attributs

    # check issue attributes
    assert_equal sla_holiday_name, sla_holiday.name
  end

  test "update_sla_holiday" do
    sla_holiday = SlaHoliday.generate!

    log_user('admin', 'admin')

    visit "/sla/holidays/#{sla_holiday.id}"
    page.first(:link, l('sla_label.sla_holiday.edit')).click
    within('form#sla-holiday-form') do
      fill_in 'Name', :with => 'mod SLA Calendar'
    end
    page.first(:button, l('sla_label.sla_holiday.save')).click
    # assert page.has_css?('#flash_notice')
    find 'div#flash_notice',
      :visible => true,
      :text => l('sla_label.sla_holiday.notice_successful_update', :id => "##{sla_holiday.id}" )    
    assert_equal 'mod SLA Calendar', sla_holiday.reload.name
    # TODO : teste in SlaHoliday#index after filtering
  end

  test "destroy_sla_holiday" do
    sla_holiday = SlaHoliday.generate!

    log_user('admin', 'admin')

    visit "/sla/holidays/#{sla_holiday.id}"
    page.first(:link, l('sla_label.sla_holiday.delete')).click
    page.accept_confirm /Are you sure/
    assert page.has_css?('#flash_notice'),
      :visible => true,
      :text => l(:notice_successful_delete)
    # TODO : teste in SlaHoliday#index after filtering
  end

end