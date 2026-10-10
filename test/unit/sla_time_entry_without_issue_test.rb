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

# File: redmine_sla/test/unit/sla_time_entry_without_issue_test.rb
# Purpose:
#   Protect SLA rendering, filtering and grouping for time entries without an issue.
#
# Redmine SLA - Redmine's Plugin

require File.expand_path('../../application_sla_units_test_case', __FILE__)

class SlaTimeEntryWithoutIssueTest < ApplicationSlaUnitsTestCase
  def setup
    super
    User.current = User.find(1)
    activity = TimeEntryActivity.create!(name: 'Unlinked SLA test', active: true)
    @entry = TimeEntry.create!(project: Project.find(1), user: User.current,
                               activity: activity, hours: 1, spent_on: Date.today)
  end

  def teardown
    User.current = nil
    super
  end

  test 'time entries without an issue have no SLA values' do
    assert_nil @entry.get_sla_level
    assert_nil @entry.get_sla_respect_1
  end

  ['slas.sla_level_id', 'slas.sla_respect_1'].each do |field|
    test "#{field} treats a time entry without an issue as missing SLA data" do
      {'=' => ['1'], '!' => ['1'], '*' => [''], '!*' => ['']}.each do |operator, values|
        query = TimeEntryQuery.new(name: 'Unlinked SLA test', project: @entry.project)
        query.filters = {}
        query.add_filter(field, operator, values)
        assert query.valid?, query.errors.full_messages.join(', ')
        assert_equal %w[! !*].include?(operator),
                     query.results_scope.where(time_entries: {id: @entry.id}).exists?
      end
    end
  end

  test 'group counts and hour totals include time entries without an issue' do
    query = TimeEntryQuery.new(name: 'Unlinked SLA groups', project: @entry.project)
    query.filters = {}
    query.add_filter('issue_id', '!*', [''])
    ['get_sla_level', 'get_sla_respect_1'].each do |column|
      query.group_by = column
      assert query.grouped?
      assert_equal({nil => 1}, query.result_count_by_group)
      assert_equal({nil => 1.0}, query.total_by_group_for(:hours))
    end
  end
end
