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

require File.expand_path('../../application_system_test_case', __FILE__)

class SlaCalendarsSystemTest < ApplicationSystemTestCase

  include Redmine::I18n

  test "create_sla_calendar" do

    log_user('admin', 'admin')
    visit '/sla/calendars/new'
    within('form#sla_calendar-form') do
      fill_in 'sla_calendar_name', :with => 'new SLA Calendar'
      find('input[name=commit]').click
    end

    # find created issue
    sla_calendar = SlaCalendar.find_by_name("new SLA Calendar")
    assert_kind_of SlaCalendar, sla_calendar

    # check redirection
    find 'div#flash_notice',
      :visible => true,
      :text => l("sla_label.sla_calendar.notice_successful_create", :id => "##{sla_calendar.id}" )
    assert_equal sla_calendars_path, current_path

    # check issue attributes
    assert_equal 'new SLA Calendar', sla_calendar.name
  end

  test "update sla_calendar name" do
    sla_calendar = SlaCalendar.generate!
    log_user('admin', 'admin')
    visit "/sla/calendars/#{sla_calendar.id}"
    page.first(:link, 'Edit').click
    within('form#sla_calendar-form') do
      fill_in 'Name', :with => 'mod SLA Calendar'
    end
    page.first(:button, l('sla_label.sla_calendar.edit')).click
    assert page.has_css?('#flash_notice')
    assert_equal 'mod SLA Calendar', sla_calendar.reload.name
  end

  test "removing sla_calendar shows confirm dialog" do
    sla_calendar = SlaCalendar.generate!
    log_user('admin', 'admin')
    visit "/sla/calendars/#{sla_calendar.id}"
    page.accept_confirm /Are you sure/ do
      first('#content a.icon-del').click
    end
  end

end