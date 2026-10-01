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

# File: redmine_sla/test/unit/sla_query_quick_wins_test.rb
# Purpose:
#   Protect query-column behavior fixed by the 3.0.1 maintenance release.
#
# Redmine SLA - Redmine's Plugin

require File.expand_path('../../application_sla_units_test_case', __FILE__)

class SlaQueryQuickWinsTest < ApplicationSlaUnitsTestCase
  test "level term priority is groupable by its display name" do
    column = SlaLevelTermQuery.new.available_columns.find { |item| item.name == :sla_priority_id }
    term = SlaLevelTerm.unscoped.find(1)

    assert column.groupable?
    assert_equal term.priority.name, column.group_value(term)
  end

  test "schedule match column is groupable" do
    column = SlaScheduleQuery.new.available_columns.find { |item| item.name == :match }

    assert column.groupable?
  end

  test "calendar holidays default to newest holiday date first" do
    assert_equal [["date", "desc"]], SlaCalendarHolidayQuery.new.default_sort_criteria
  end
end
