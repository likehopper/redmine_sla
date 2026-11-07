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

# File: redmine_sla/test/unit/sla_get_date_test.rb
# Purpose:
#   sla_get_date reads the configured time zone from the plugin settings.
#   Zone names offered by the settings page contain "_", digits, "+" or "-".
#
# Redmine SLA - Redmine's Plugin

require File.expand_path('../../application_sla_units_test_case', __FILE__)

class SlaGetDateTest < ApplicationSlaUnitsTestCase
  UTC_NOON = '2026-01-15 12:00:00'

  {
    'Etc/UTC' => '2026-01-15 12:00',
    'Europe/Paris' => '2026-01-15 13:00',
    'America/New_York' => '2026-01-15 07:00',
    'America/Argentina/Buenos_Aires' => '2026-01-15 09:00',
    'Etc/GMT+12' => '2026-01-15 00:00'
  }.each do |zone, expected|
    test "sla_get_date converts UTC to #{zone}" do
      Setting.plugin_redmine_sla = Setting.plugin_redmine_sla.merge('sla_time_zone' => zone)

      assert_equal expected, sla_date(UTC_NOON)
    end
  end

  private

  def sla_date(utc_time)
    value = ActiveRecord::Base.connection.select_value(
      ActiveRecord::Base.sanitize_sql(['SELECT sla_get_date(?)', utc_time])
    )
    assert_not_nil value, "sla_get_date returned NULL"
    Time.parse(value.to_s).strftime('%Y-%m-%d %H:%M')
  end
end
