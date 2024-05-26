# frozen_string_literal: true

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

module SlaCalendarsHelperSystemTest

  def contextual_menu_sla_calendar
    sla_calendar = SlaCalendar.find(1)

    visit '/sla/calendars/'
    assert_text l('sla_label.sla_calendar.index')
    element = find('tr#entity_id_1')
    element.right_click
    assert_selector 'div#context-menu', visible: true
    assert_selector 'div#context-menu a', text: 'Show'
    find('div#context-menu a', text: l(:button_show)).click
    assert_current_path sla_calendar_path(sla_calendar)
    assert_text l('sla_label.sla_calendar.show')
    assert_text sla_calendar.name

    visit '/sla/calendars/'
    assert_text l('sla_label.sla_calendar.index')
    element = find('tr#entity_id_1')
    element.right_click
    assert_selector 'div#context-menu', visible: true
    assert_selector 'div#context-menu a', text: l(:button_edit)
    find('div#context-menu a', text: l(:button_edit)).click
    assert_current_path edit_sla_calendar_path(sla_calendar)
    assert_text l('sla_label.sla_calendar.edit')
    assert_field 'sla_calendar_name', with: sla_calendar.name

    visit '/sla/calendars/'
    assert_text l('sla_label.sla_calendar.index')
    element = find('tr#entity_id_1')
    element.right_click
    assert_selector 'div#context-menu', visible: true
    assert_selector 'div#context-menu a', text: l(:button_delete)
    accept_confirm do
      find('div#context-menu a', text: l(:button_delete)).click
    end
    assert_current_path sla_calendars_path()
    assert_text l(:notice_successful_delete)
    
  end 

  def create_sla_calendar(sla_calendar_name)
    visit '/sla/calendars/new'
    within('form#sla-calendar-form') do
      fill_in 'sla_calendar_name', :with => sla_calendar_name
      find('input[name=commit]').click
    end

    # find created issue
    sla_calendar = SlaCalendar.find_by_name(sla_calendar_name)
    assert_kind_of SlaCalendar, sla_calendar

    # check redirection
    find 'div#flash_notice',
      :visible => true,
      :text => l("sla_label.sla_calendar.notice_successful_create", :id => "##{sla_calendar.id}" )
    assert_equal sla_calendars_path, current_path

    # TODO : vérifier SlaCalendar#show
    # visit "/sla/calendares/#{sla_calendar.id}"
    # compate sla_calendar attributs

    # check issue attributes
    assert_equal sla_calendar_name, sla_calendar.name
  end

  def update_sla_calendar
    sla_calendar = SlaCalendar.generate!
    visit "/sla/calendars/#{sla_calendar.id}"
    page.first(:link, l('sla_label.sla_calendar.edit')).click
    within('form#sla-calendar-form') do
      fill_in 'Name', :with => 'mod SLA Calendar'
    end
    page.first(:button, l('sla_label.sla_calendar.save')).click
    # assert page.has_css?('#flash_notice')
    find 'div#flash_notice',
      :visible => true,
      :text => l('sla_label.sla_calendar.notice_successful_update', :id => "##{sla_calendar.id}" )    
    assert_equal 'mod SLA Calendar', sla_calendar.reload.name
    # TODO : teste in SlaCalendar#index after filtering
  end

  def destroy_sla_calendar
    sla_calendar = SlaCalendar.generate!
    visit "/sla/calendars/#{sla_calendar.id}"
    page.first(:link, l('sla_label.sla_calendar.delete')).click
    page.accept_confirm /Are you sure/
    assert page.has_css?('#flash_notice'),
      :visible => true,
      :text => l(:notice_successful_delete)
    # TODO : teste in SlaCalendar#index after filtering
  end

end