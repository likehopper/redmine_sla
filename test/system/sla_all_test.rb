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

require_relative "../application_system_test_case"

require_relative "slas_helper"
require_relative "sla_types_helper"
require_relative "sla_statuses_helper"
require_relative "sla_calendars_helper"

class SlaAllSystemTest < ApplicationSystemTestCase

  include Redmine::I18n

  include SlasHelperSystemTest
  include SlaTypesHelperSystemTest
  include SlaStatusesHelperSystemTest
  include SlaCalendarsHelperSystemTest

  test "full create storyline as admin" do
    log_user('admin', 'admin')
    create_sla('new Sla')
    create_sla_type('new SLA Type')
    create_sla_status('new SLA Type','New')
    create_sla_calendar('new SLA Calendar')
  end
  
  test "all contextual menu as admin" do
    log_user('admin', 'admin')
    contextual_menu_sla_calendar
    contextual_menu_sla_status
    contextual_menu_sla_type
    contextual_menu_sla
  end

  test "all update as admin" do    
    log_user('admin', 'admin')
    update_sla
    update_sla_type
    update_sla_status
    update_sla_calendar  
  end

  test "all destroy as admin" do
    log_user('admin', 'admin')
    destroy_sla_calendar
    destroy_sla_status
    destroy_sla_type
    destroy_sla
  end

end