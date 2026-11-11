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

# File: redmine_sla/test/unit/sla_project_visibility_test.rb
# Purpose:
#   Protect project-scoped visibility for SLA configuration catalogs.
#
# Redmine SLA - Redmine's Plugin

require File.expand_path('../../application_sla_units_test_case', __FILE__)

class SlaProjectVisibilityTest < ApplicationSlaUnitsTestCase

  def setup
    super
    User.current = User.find(3) # Resolver in projects 1 and 4.
  end

  def teardown
    User.current = nil
    super
  end

  test "visible scopes include only catalogs from authorized projects" do
    assert_equal [1, 2, 7, 8], Sla.visible.order(:id).pluck(:id)
    assert_equal [1, 2, 9, 10], SlaLevel.visible.order(:id).pluck(:id)
    assert_equal [1], SlaCalendar.visible.order(:id).pluck(:id)
  end

  test "visible catalog scopes are empty without view_sla, for non-members and anonymous" do
    # reporter: member without SLA permission; other: no membership.
    [User.find(5), User.find(6), User.anonymous].each do |user|
      assert_catalogs_hidden_from(user)
    end
  end

  test "visible catalog scopes stay empty for anonymous and non-members of a public project" do
    Project.find(1).update_column(:is_public, true)
    [Role.anonymous, Role.non_member].each { |role| role.add_permission!(:view_issues) }
    assert Project.find(1).visible?(User.find(6))

    [User.find(6), User.anonymous].each do |user|
      assert_catalogs_hidden_from(user)
    end
  end

  test "visible catalog scopes of a member of other projects only include those projects" do
    sysadmin = User.find(4) # Resolver in projects 2 and 3.
    assert_equal [3, 4, 5, 6], Sla.visible(sysadmin).order(:id).pluck(:id)
    assert_equal [3, 4, 5, 6, 7, 8], SlaLevel.visible(sysadmin).order(:id).pluck(:id)
    assert_empty Sla.visible(sysadmin).where(id: [1, 2, 7, 8])
  end

  test "visible catalog scopes exclude projects with the SLA module disabled" do
    Project.find(4).disable_module!(:sla)
    assert_equal [1, 2], Sla.visible.order(:id).pluck(:id)
    assert_equal [1, 2], SlaLevel.visible.order(:id).pluck(:id)
  end

  test "visible catalog scopes exclude archived projects" do
    Project.find(4).update_column(:status, Project::STATUS_ARCHIVED)
    assert_equal [1, 2], Sla.visible.order(:id).pluck(:id)
    assert_equal [1, 2], SlaLevel.visible.order(:id).pluck(:id)
  end

  test "visible cache scopes include only projects where the user has view_sla" do
    [SlaCache, SlaCacheSpent].each do |klass|
      assert_equal [1, 4], klass.visible.distinct.pluck(:project_id).sort, klass.name
      assert_operator klass.where(project_id: [2, 3]).count, :>, 0, klass.name
    end
  end

  test "visible cache scopes are empty without view_sla, for non-members and anonymous" do
    [User.find(5), User.find(6), User.anonymous].each do |user|
      [SlaCache, SlaCacheSpent].each do |klass|
        assert_operator klass.count, :>, 0
        assert_empty klass.visible(user), "#{klass.name} visible to #{user.login.presence || 'anonymous'}"
      end
    end
  end

  test "visible cache scopes exclude a project whose SLA module is disabled without purge" do
    # Bypass the purge callback: rows left behind must still be hidden.
    EnabledModule.where(project_id: 4, name: 'sla').delete_all
    [SlaCache, SlaCacheSpent].each do |klass|
      assert_operator klass.where(project_id: 4).count, :>, 0, klass.name
      assert_equal [1], klass.visible.distinct.pluck(:project_id), klass.name
    end
  end

  test "visible project tracker scope requires manage_sla" do
    assert_equal SlaProjectTracker.count, SlaProjectTracker.visible(User.find(2)).count
    [User.find(3), User.find(5), User.find(6), User.anonymous].each do |user|
      assert_empty SlaProjectTracker.visible(user), user.login
    end
  end

  test "project scopes include only catalogs used by that project" do
    project = Project.find(1)

    assert_equal [1, 2], Sla.in_project(project).order(:id).pluck(:id)
    assert_equal [1, 2], SlaLevel.in_project(project).order(:id).pluck(:id)
    assert_equal [1], SlaCalendar.in_project(project).order(:id).pluck(:id)
  end

  test "level query filter values do not expose other project catalogs" do
    query = SlaLevelQuery.new(project: Project.find(1))

    assert_equal [["SLA TMA tracker_bug_request", "1"],
                  ["SLA TMA tracker_support_request", "2"]], query.all_sla_values
    assert_equal [["TMA - HO", "1"]], query.all_sla_calendar_values
    assert_empty query.all_sla_custom_fields_values
  end

  test "custom field filter excludes fields used only by forbidden projects and unused fields" do
    IssueCustomField.find(2).update_column(:is_required, true)
    SlaLevel.find(3).update_column(:custom_field_id, 2)

    assert_equal [["SlaPriorityScf", "1"]], SlaLevelQuery.new.all_sla_custom_fields_values
    assert_equal [["SlaPriorityScf", "1"]],
                 SlaLevelQuery.new(project: Project.find(4)).all_sla_custom_fields_values
    assert_empty SlaLevelQuery.new(project: Project.find(2)).all_sla_custom_fields_values
  end

  test "custom field filter excludes fields hidden from the user" do
    IssueCustomField.find(1).update_column(:visible, false)

    assert_empty SlaLevelQuery.new.all_sla_custom_fields_values
  end

  test "custom field filter is empty without SLA permission or for anonymous users" do
    [User.find(5), User.anonymous].each do |user|
      User.current = user
      assert_empty SlaLevelQuery.new.all_sla_custom_fields_values
    end
  end

  test "administrator custom field filter includes referenced fields and respects project context" do
    User.current = User.find(1)
    IssueCustomField.find(2).update_column(:is_required, true)
    SlaLevel.find(3).update_column(:custom_field_id, 2)

    assert_equal [["SlaPriorityScf", "1"], ["IsNotRequired", "2"]],
                 SlaLevelQuery.new.all_sla_custom_fields_values.sort_by { |_, id| id.to_i }
    assert_equal [["IsNotRequired", "2"]],
                 SlaLevelQuery.new(project: Project.find(2)).all_sla_custom_fields_values
  end

  test "cache level filters respect global and project permissions" do
    [SlaCacheQuery, SlaCacheSpentQuery].each do |klass|
      assert_equal [1, 2, 9, 10], klass.new.all_sla_level_values.map { |_, id| id.to_i }.sort
      assert_equal [1, 2], klass.new(project: Project.find(1)).all_sla_level_values.map { |_, id| id.to_i }.sort
      assert_empty klass.new(project: Project.find(2)).all_sla_level_values
    end
  end

  test "cache level filters do not expose catalogs without SLA permission" do
    [User.find(5), User.anonymous].each do |user|
      User.current = user
      [SlaCacheQuery, SlaCacheSpentQuery].each do |klass|
        assert_empty klass.new.all_sla_level_values
        assert_empty klass.new(project: Project.find(1)).all_sla_level_values
      end
    end
  end

  test "administrator cache level filters still respect project context" do
    User.current = User.find(1)
    [SlaCacheQuery, SlaCacheSpentQuery].each do |klass|
      assert_equal (1..10).to_a, klass.new.all_sla_level_values.map { |_, id| id.to_i }.sort
      assert_equal [1, 2], klass.new(project: Project.find(1)).all_sla_level_values.map { |_, id| id.to_i }.sort
    end
  end

  test "issue and time entry SLA filters respect project permissions" do
    [IssueQuery, TimeEntryQuery].each do |klass|
      allowed = klass.new(project: Project.find(1)).available_filters
      assert_equal [1, 2], allowed.fetch('slas.sla_level_id')[:values].map { |_, id| id.to_i }.sort

      forbidden = klass.new(project: Project.find(2)).available_filters
      assert_empty forbidden.keys.grep(/\Aslas\./)
    end
  end

  test "issue and time entry SLA filters are absent without permission" do
    [User.find(5), User.anonymous].each do |user|
      User.current = user
      [IssueQuery, TimeEntryQuery].each do |klass|
        assert_empty klass.new(project: Project.find(1)).available_filters.keys.grep(/\Aslas\./)
      end
    end
  end

  test "issue and time entry SLA filters are absent for archived projects" do
    project = Project.find(1)
    project.update_column(:status, Project::STATUS_ARCHIVED)
    [IssueQuery, TimeEntryQuery].each do |klass|
      assert_empty klass.new(project: project).available_filters.keys.grep(/\Aslas\./)
    end
  end

  private

  def assert_catalogs_hidden_from(user)
    assert_operator Sla.visible(User.find(1)).count, :>, 0
    assert_empty Sla.visible(user), "SLAs visible to #{user.login.presence || 'anonymous'}"
    assert_empty SlaLevel.visible(user), "SLA levels visible to #{user.login.presence || 'anonymous'}"
    assert_empty SlaCalendar.visible(user), "SLA calendars visible to #{user.login.presence || 'anonymous'}"
  end

end
