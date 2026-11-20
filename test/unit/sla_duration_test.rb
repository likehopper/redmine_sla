# frozen_string_literal: true
# File: redmine_sla/test/unit/sla_duration_test.rb
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

require File.expand_path('../../application_sla_units_test_case', __FILE__)

class SlaDurationTest < ActiveSupport::TestCase
  # Pure formatting checks: no fixtures needed.
  self.fixture_table_names = []

  class DurationView
    include RedmineSla::Helpers::SlaRenderingHelper
  end

  test 'durations omit a trailing zero unit' do
    view = DurationView.new
    {
      0 => '0m', 1 => '1m', 30 => '30m', 60 => '1h', 61 => '1h1m',
      120 => '2h', 270 => '4h30m', 540 => '9h', 4020 => '67h', 93_240 => '1554h'
    }.each do |minutes, expected|
      assert_equal expected, view.sla_duration(minutes), "#{minutes} minutes"
    end
  end
end
