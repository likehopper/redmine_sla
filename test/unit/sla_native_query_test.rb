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

# File: redmine_sla/test/unit/sla_native_query_test.rb
# Purpose:
#   Protect native SLA filtering, sorting and grouping results.
#
# Redmine SLA - Redmine's Plugin

require File.expand_path('../../application_sla_units_test_case', __FILE__)

class SlaNativeQueryTest < ApplicationSlaUnitsTestCase
  def setup
    super
    User.current = User.find(1)
  end

  def teardown
    User.current = nil
    super
  end

  [IssueQuery, TimeEntryQuery].each do |query_class|
    [1, 4].each do |project_id|
      test "#{query_class} SLA respect filters match displayed issue values in project #{project_id}" do
        project = Project.find(project_id)
        issues = project.issues.order(:id).to_a
        expected = issues.group_by { |issue| issue.get_sla_respect(1) }
        assert expected[true].present?
        assert expected[false].present?

        if query_class == TimeEntryQuery
          activity = TimeEntryActivity.create!(name: 'SLA query test', active: true)
          issues.each do |issue|
            TimeEntry.create!(project: project, issue: issue, user: User.current,
                              activity: activity, hours: 1, spent_on: Date.today)
          end
        end

        [true, false].each do |respect|
          query = query_class.new(name: 'SLA query test', project: project)
          query.filters = {}
          query.add_filter('slas.sla_respect_1', '=', [respect ? '1' : '0'])
          assert query.valid?, query.errors.full_messages.join(', ')
          rows = query_class == IssueQuery ? query.issues : query.results_scope.to_a
          ids = rows.map { |row| query_class == IssueQuery ? row.id : row.issue_id }
          assert_equal expected.fetch(respect).map(&:id).sort, ids.uniq.sort

          query.group_by = 'get_sla_respect_1'
          assert_equal({respect => rows.size}, query.result_count_by_group)
          query.sort_criteria = [['get_sla_respect_1', 'asc']]
          sorted_rows = query_class == IssueQuery ? query.issues : query.results_scope.to_a
          assert_equal rows.map(&:id).sort, sorted_rows.map(&:id).sort
        end

        query = query_class.new(name: 'SLA exclusion test', project: project)
        query.filters = {}
        query.add_filter('slas.sla_respect_1', '!', ['1'])
        assert query.valid?, query.errors.full_messages.join(', ')
        rows = query_class == IssueQuery ? query.issues : query.results_scope.to_a
        ids = rows.map { |row| query_class == IssueQuery ? row.id : row.issue_id }.uniq
        assert_equal (issues.map(&:id) - expected.fetch(true).map(&:id)).sort, ids.sort

        {'=' => ['1', '0'], '!' => ['1', '0'], '*' => [''], '!*' => ['']}.each do |operator, values|
          query = query_class.new(name: 'SLA presence test', project: project)
          query.filters = {}
          query.add_filter('slas.sla_respect_1', operator, values)
          assert query.valid?, query.errors.full_messages.join(', ')
          rows = query_class == IssueQuery ? query.issues : query.results_scope.to_a
          ids = rows.map { |row| query_class == IssueQuery ? row.id : row.issue_id }.uniq
          expected_ids = %w[! !*].include?(operator) ? expected.fetch(nil, []).map(&:id) :
                           expected.fetch(true).map(&:id) + expected.fetch(false).map(&:id)
          assert_equal expected_ids.sort, ids.sort
        end

        levels = issues.to_h { |issue| [issue.id, issue.get_sla_level&.id] }
        selected_level = levels.values.compact.first
        {'=' => [selected_level.to_s], '!' => [selected_level.to_s], '*' => [''], '!*' => ['']}.each do |operator, values|
          query = query_class.new(name: 'SLA level test', project: project)
          query.filters = {}
          query.add_filter('slas.sla_level_id', operator, values)
          assert query.valid?, query.errors.full_messages.join(', ')
          rows = query_class == IssueQuery ? query.issues : query.results_scope.to_a
          ids = rows.map { |row| query_class == IssueQuery ? row.id : row.issue_id }.uniq
          expected_ids = levels.select do |_, level_id|
            case operator
            when '=' then level_id == selected_level
            when '!' then level_id != selected_level
            when '*' then !level_id.nil?
            when '!*' then level_id.nil?
            end
          end.keys
          assert_equal expected_ids.sort, ids.sort
        end

        query = query_class.new(name: 'SLA grouped results test', project: project)
        query.filters = {}
        query.available_filters
        query.group_by = 'get_sla_respect_1'
        assert query.grouped?
        query.sort_criteria = [['get_sla_respect_1', 'asc']]
        rows = query_class == IssueQuery ? query.issues : query.results_scope.to_a
        grouped_rows = rows.group_by do |row|
          issue = query_class == IssueQuery ? row : row.issue
          issue.get_sla_respect(1)
        end
        assert_equal grouped_rows.transform_values(&:size), query.result_count_by_group
        codes = rows.map do |row|
          issue = query_class == IssueQuery ? row : row.issue
          {nil => 0, false => 1, true => 2}.fetch(issue.get_sla_respect(1))
        end
        assert_equal codes.sort, codes
        if query_class == TimeEntryQuery
          assert_equal grouped_rows.transform_values { |entries| entries.sum(&:hours).to_f },
                       query.total_by_group_for(:hours)
        end

        query.group_by = 'get_sla_level'
        level_groups = rows.group_by do |row|
          issue = query_class == IssueQuery ? row : row.issue
          query.group_by_column.group_value(issue)
        end
        assert_equal level_groups.transform_values(&:size), query.result_count_by_group
      end
    end
  end
end
