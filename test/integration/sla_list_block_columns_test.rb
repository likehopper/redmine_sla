# frozen_string_literal: true
# File: redmine_sla/test/integration/sla_list_block_columns_test.rb
# SPDX-License-Identifier: GPL-2.0-or-later

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

require_relative '../application_sla_integration_test_case'

# Render the actual lists with two block columns, including lists that do not
# currently offer one. Assert the HTML structure rather than ERB source syntax.
class SlaListBlockColumnsTest < ApplicationSlaIntegrationTestCase
  {
    'slas' => SlaQuery, 'calendars' => SlaCalendarQuery,
    'levels' => SlaLevelQuery, 'holidays' => SlaHolidayQuery,
    'schedules' => SlaScheduleQuery, 'statuses' => SlaStatusQuery,
    'level_terms' => SlaLevelTermQuery, 'calendar_holidays' => SlaCalendarHolidayQuery,
    'project_trackers' => SlaProjectTrackerQuery, 'caches' => SlaCacheQuery,
    'cache_spents' => SlaCacheSpentQuery
  }.each do |resource, query_class|
    test "#{resource} list renders multiple block columns spanning the full row" do
      User.current = User.find(1)
      if %w[caches cache_spents].include?(resource)
        SlaCache.find_by_issue_id(7)
        SlaCacheSpent.find_by_issue_and_type_id(Issue.find(7), 1)
      end
      log_user('admin', 'admin')
      # IDs are available on every entity. Duplicate block columns exercise the
      # caption branch without adding fictitious attributes to the models.
      query_class.any_instance.stubs(:block_columns).returns([
        QueryColumn.new(:id, :inline => false), QueryColumn.new(:id, :inline => false)
      ])
      parameters = {:set_filter => 1, :c => ['id']}
      if %w[caches cache_spents].include?(resource)
        parameters.merge!(:f => ['issue.status_id'], :op => {'issue.status_id' => '*'})
      end
      get "/sla/#{resource}", :params => parameters
      assert_response :success
      document = Nokogiri::HTML(response.body)
      entity_row = document.at_css('tr.entity')
      assert entity_row, "#{resource} should contain a fixture row"
      first_block_row = entity_row.next_element
      second_block_row = first_block_row.next_element
      [first_block_row, second_block_row].each do |block_row|
        cell = block_row.at_css('td')
        assert_equal entity_row.css('td').size, cell['colspan'].to_i, resource
        assert cell.at_css('span'), "#{resource} should show captions for multiple block columns"
        assert_includes cell.text, entity_row['id'][/\d+\z/], "#{resource} should render the entity ID"
      end
    end
  end

  ### SLA columns in project issue lists ###

  ISSUE_LIST_PARAMS = {
    set_filter: 1, f: ['status_id'], op: { status_id: '*' },
    c: %w[subject get_sla_level get_sla_respect_1], per_page: 100
  }.freeze

  test "issue list shows SLA columns to a member with view_sla" do
    log_user('developer', 'developer')
    get '/projects/project-sla-tests-tma/issues', params: ISSUE_LIST_PARAMS
    assert_response :success
    assert_select 'table.issues th', text: l('sla_label.sla_level.singular')
    assert_select "tr#issue-#{sla_issue.id} td.get_sla_level a", text: sla_issue_level.name
    assert_select "tr#issue-#{sla_issue.id} td.get_sla_respect_1", 1
  end

  test "issue list hides SLA columns from a member without view_sla" do
    log_user('reporter', 'reporter')
    get '/projects/project-sla-tests-tma/issues', params: ISSUE_LIST_PARAMS
    assert_sla_issue_columns_hidden
  end

  test "issue list hides SLA columns when the SLA module is disabled" do
    # Resolve the issue before disabling the module purges its cache.
    sla_issue
    Project.find(1).disable_module!(:sla)
    %w[developer admin].each do |login|
      reset!
      log_user(login, login)
      get '/projects/project-sla-tests-tma/issues', params: ISSUE_LIST_PARAMS
      assert_sla_issue_columns_hidden
    end
  end

  test "issue list hides SLA columns from anonymous and non-members of a public project" do
    Project.find(1).update_column(:is_public, true)
    [Role.anonymous, Role.non_member].each { |role| role.add_permission!(:view_issues) }
    with_settings login_required: '0' do
      get '/projects/project-sla-tests-tma/issues', params: ISSUE_LIST_PARAMS
      assert_sla_issue_columns_hidden

      # sysadmin holds view_sla in projects 2 and 3 only.
      %w[other sysadmin].each do |login|
        reset!
        log_user(login, login)
        get '/projects/project-sla-tests-tma/issues', params: ISSUE_LIST_PARAMS
        assert_sla_issue_columns_hidden
      end
    end
  end

  { 'Resolver' => true, 'Reporter' => false }.each do |role_name, level_visible|
    test "parent issue list #{level_visible ? 'shows' : 'hides'} the subproject SLA level with the #{role_name} role there" do
      subproject_issue = create_subproject_issue_with_sla(Role.find_by!(name: role_name))
      log_user('developer', 'developer')

      with_settings display_subprojects_issues: '1' do
        get '/projects/project-sla-tests-tma/issues', params: ISSUE_LIST_PARAMS
      end
      assert_response :success
      # The parent project row keeps its level: the column itself is offered.
      assert_select "tr#issue-#{sla_issue.id} td.get_sla_level a", text: sla_issue_level.name
      assert_select "tr#issue-#{subproject_issue.id} td.get_sla_level a", level_visible ? 1 : 0
    end
  end

  { 'Resolver' => true, 'Reporter' => false }.each do |role_name, level_visible|
    test "parent issue CSV export #{level_visible ? 'includes' : 'omits'} the subproject SLA level with the #{role_name} role there" do
      subproject_issue = create_subproject_issue_with_sla(Role.find_by!(name: role_name))
      log_user('developer', 'developer')

      with_settings display_subprojects_issues: '1' do
        get '/projects/project-sla-tests-tma/issues.csv', params: ISSUE_LIST_PARAMS
      end
      assert_response :success
      rows = CSV.parse(response.body.force_encoding('UTF-8').sub(/\A﻿/, ''))
      parent_row = rows.detect { |row| row.first == sla_issue.id.to_s }
      level_index = parent_row.index(sla_issue_level.name)
      assert level_index, 'the parent project row exports its SLA level'
      subproject_row = rows.detect { |row| row.first == subproject_issue.id.to_s }
      assert subproject_row, 'the subproject issue is exported'
      if level_visible
        assert_equal sla_issue_level.name, subproject_row[level_index]
      else
        assert_nil subproject_row[level_index].presence
      end
    end

    test "parent issue grouping and filters #{level_visible ? 'count' : 'ignore'} the subproject SLA level with the #{role_name} role there" do
      subproject_issue = create_subproject_issue_with_sla(Role.find_by!(name: role_name))
      subproject_issue.get_sla_spent(1)
      assert SlaCacheSpent.exists?(issue_id: subproject_issue.id, sla_type_id: 1)
      developer = User.find_by_login!('developer')

      with_settings display_subprojects_issues: '1' do
        all_counts = sla_level_group_counts(User.find(1))
        developer_counts = sla_level_group_counts(developer)
        hidden = level_visible ? 0 : 1
        assert_equal all_counts[sla_issue_level.name] - hidden, developer_counts[sla_issue_level.name]

        by_level = filtered_issue_ids(developer, 'slas.sla_level_id', '=', [sla_issue_level.id.to_s])
        by_respect = filtered_issue_ids(developer, 'slas.sla_respect_1', '*', [''])
        assert_includes by_level, sla_issue.id
        assert_equal level_visible, by_level.include?(subproject_issue.id)
        assert_equal level_visible, by_respect.include?(subproject_issue.id)
        # The administrator sees every row: the hidden case is a permission effect.
        assert_includes filtered_issue_ids(User.find(1), 'slas.sla_respect_1', '*', ['']), subproject_issue.id
      end
    end

    test "parent time entry list #{level_visible ? 'shows' : 'hides'} the subproject SLA level with the #{role_name} role there" do
      subproject_issue = create_subproject_issue_with_sla(Role.find_by!(name: role_name))
      subproject_issue.project.enable_module!(:time_tracking)
      entry = TimeEntry.create!(project: subproject_issue.project, issue: subproject_issue, user: User.find_by_login!('developer'),
                                author: User.find_by_login!('developer'),
                                hours: 1, spent_on: Date.today, activity: time_entry_activity)
      log_user('developer', 'developer')

      with_settings display_subprojects_issues: '1' do
        get '/projects/project-sla-tests-tma/time_entries',
            params: { set_filter: 1, f: ['spent_on'], op: { spent_on: '*' }, c: %w[issue get_sla_level], per_page: 100 }
      end
      assert_response :success
      assert_select "tr#time-entry-#{entry.id}", 1
      assert_select "tr#time-entry-#{entry.id} td.get_sla_level a", level_visible ? 1 : 0
    end
  end

  test "SLA type list keeps one reorderable row per type" do
    log_user('admin', 'admin')
    assert_empty SlaTypeQuery.new.available_block_columns
    get '/sla/types'
    assert_response :success
    assert_select 'table.sla_types tbody tr', :count => SlaType.count
  end

  private

  def sla_issue
    @sla_issue ||= Issue.find(SlaCache.find_by!(project_id: 1, sla_level_id: 1).issue_id)
  end

  def sla_issue_level
    SlaLevel.find(1)
  end

  # Issue counts per SLA level name in project 1 and its subprojects, as seen by user.
  def sla_level_group_counts(user)
    User.current = user
    query = IssueQuery.new(name: '_', project: Project.find(1), group_by: 'get_sla_level')
    query.add_filter('status_id', '*', [''])
    query.result_count_by_group
  ensure
    User.current = nil
  end

  def filtered_issue_ids(user, field, operator, values)
    User.current = user
    query = IssueQuery.new(name: '_', project: Project.find(1))
    query.add_filter('status_id', '*', [''])
    query.add_filter(field, operator, values)
    query.issue_ids
  ensure
    User.current = nil
  end

  def time_entry_activity
    TimeEntryActivity.first || TimeEntryActivity.create!(name: 'SLA test activity', active: true)
  end

  def assert_sla_issue_columns_hidden
    assert_response :success
    assert_select "tr#issue-#{sla_issue.id}", 1
    assert_select 'td.get_sla_level, td.get_sla_respect_1', 0
    assert_not response.body.include?(sla_issue_level.name), 'issue list exposes the SLA level'
  end

  # Subproject of project 1 using the same SLA on the bug tracker, where the
  # developer holds the given role.
  def create_subproject_issue_with_sla(role)
    subproject = Project.create!(name: 'SLA subproject', identifier: 'sla-subproject',
                                 is_public: false, tracker_ids: [1],
                                 enabled_module_names: %w[issue_tracking sla])
    subproject.set_parent!(Project.find(1))
    Member.create!(project: subproject, principal: User.find_by_login!('developer'), role_ids: [role.id])
    SlaProjectTracker.create!(project: subproject, tracker_id: 1, sla_id: 1)
    issue = Issue.create!(project: subproject, tracker_id: 1, subject: 'Subproject SLA issue',
                          author_id: 1, status_id: sla_issue.status_id, priority_id: sla_issue.priority_id,
                          created_on: sla_issue.created_on)
    assert_equal 1, SlaCache.find_by_issue_id(issue.id)&.sla_level_id
    issue
  end
end
