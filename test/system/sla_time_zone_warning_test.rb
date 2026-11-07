# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Redmine SLA - service level agreement plugin
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

# File: redmine_sla/test/system/sla_time_zone_warning_test.rb
# Purpose:
#   Changing the SLA time zone does not recalculate existing SLA times:
#   the settings page warns the administrator before saving.
#
# Redmine SLA - Redmine's Plugin

require_relative '../application_sla_system_test_case'

class SlaTimeZoneWarningSystemTest < ApplicationSlaSystemTestCase
  test "selecting another time zone shows the warning until the saved zone is selected again" do
    log_user('admin', 'admin')
    visit '/settings/plugin/redmine_sla'
    find('#tab-sla_zone').click
    saved_zone = find('#settings_sla_time_zone').value

    assert_selector '#settings_sla_time_zone ~ em.info'
    assert_no_selector '#sla_time_zone_change_warning', visible: true

    select 'America/New_York', from: 'settings_sla_time_zone'
    assert_selector '#sla_time_zone_change_warning', visible: true

    find('#settings_sla_time_zone').find("option[value='#{saved_zone}']").select_option
    assert_no_selector '#sla_time_zone_change_warning', visible: true
  end
end
