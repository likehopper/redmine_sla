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

# File: redmine_sla/test/unit/sla_generated_time_entries_test.rb

require_relative '../application_sla_units_test_case'

# Consume generated records inside each transaction, keeping other suites isolated.
class SlaGeneratedTimeEntriesTest < ApplicationSlaUnitsTestCase
  def setup
    super
    User.current = User.find(1)
    @entries = YAML.load_file(Rails.root.join('plugins/redmine_sla/test/fixtures/time_entries.yml')).values
  end

  def teardown
    User.current = nil
    super
  end

  test 'generated time entries are valid native records' do
    assert_not_empty @entries
    @entries.each do |attributes|
      entry = TimeEntry.new(attributes)
      assert entry.valid?, "Time entry #{attributes['id']}: #{entry.errors.full_messages.join(', ')}"
      assert_equal 0.5, entry.hours.to_f
      assert_equal entry.issue.project_id, entry.project_id
    end
  end

  test 'every status transition including reopening has work recorded thirty minutes before it' do
    journals = YAML.load_file(Rails.root.join('plugins/redmine_sla/test/fixtures/journals.yml')).values
    expected = journals.map do |journal|
      recorded_at = (DateTime.parse(journal.fetch('created_on')) - Rational(1, 48)).new_offset(0)
      [journal.fetch('journalized_id').to_i, journal.fetch('user_id').to_i, recorded_at.strftime('%Y-%m-%d %H:%M:%S')]
    end
    ordinary_issue = Issue.find_by!(subject: 'Issue in a project without SLA')
    actual = @entries.reject { |entry| entry['issue_id'] == ordinary_issue.id }.map do |entry|
      [entry.fetch('issue_id'), entry.fetch('user_id').to_i, entry.fetch('created_on')]
    end
    assert_equal expected.sort, actual.sort
  end

  test 'ordinary issue and generated time entry do not expose SLA filters' do
    project = Project.find_by!(identifier: 'project-without-sla-with-issue')
    assert_not project.module_enabled?(:sla)
    assert project.module_enabled?(:time_tracking)
    assert_empty Project.find_by!(identifier: 'another-project-without-sla').issues
    assert_equal 1, project.issues.count
    assert_empty project.sla_project_trackers
    issue = project.issues.first!
    entry = TimeEntry.create!(@entries.find { |attributes| attributes['issue_id'] == issue.id })
    assert_nil issue.get_sla_level
    assert_nil entry.get_sla_level
    assert_nil entry.get_sla_respect_1

    [IssueQuery, TimeEntryQuery].each do |query_class|
      query = query_class.new(name: 'Generated ordinary work', project: project)
      query.filters = {}
      assert query.valid?, query.errors.full_messages.join(', ')
      rows = query_class == IssueQuery ? query.issues : query.results_scope
      assert rows.any?
      assert_empty query.available_filters.keys.grep(/\Aslas\./)
    end
  end

  test 'generated time entry shares its issue SLA values and query visibility' do
    issue = Issue.find(SlaCache.first.issue_id)
    entry = TimeEntry.create!(@entries.find { |attributes| attributes['issue_id'] == issue.id })
    assert_not_nil issue.get_sla_level
    assert_not_nil issue.get_sla_respect(1)
    assert_equal issue.get_sla_level.id, entry.get_sla_level.id
    assert_equal issue.get_sla_respect(1), entry.get_sla_respect_1
    query = TimeEntryQuery.new(name: 'Generated SLA work', project: issue.project)
    query.filters = {}
    query.add_filter('slas.sla_level_id', '=', [issue.get_sla_level.id.to_s])
    assert query.valid?, query.errors.full_messages.join(', ')
    assert_equal [entry.id], query.results_scope.pluck(:id)
  end
end
