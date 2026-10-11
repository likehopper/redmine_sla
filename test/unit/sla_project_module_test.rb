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

# File: redmine_sla/test/unit/sla_project_module_test.rb
# Purpose:
#   Disabling the SLA module of a project keeps its SLA configuration,
#   purges its SLA cache and stops any further SLA calculation, explanation
#   included. See sla_update_sla_task_test.rb for the update_sla clean-up.
#
# Redmine SLA - Redmine's Plugin

require File.expand_path('../../application_sla_units_test_case', __FILE__)

class SlaProjectModuleTest < ApplicationSlaUnitsTestCase
  def setup
    @project = Project.find(1)
    @issue = Issue.find(4)
    assert_equal @project.id, @issue.project_id
    assert_not_nil @issue.get_sla_level
    assert_not_nil @issue.get_sla_spent(1)
    assert SlaCacheSpent.where(project_id: @project.id).exists?
  end

  test "disabling the module from project settings purges the cache only" do
    trackers = SlaProjectTracker.where(project_id: @project.id).pluck(:id)
    assert_not_empty trackers

    @project.enabled_module_names = @project.enabled_module_names - ['sla']

    assert_not SlaCache.where(project_id: @project.id).exists?
    assert_not SlaCacheSpent.where(project_id: @project.id).exists?
    assert_equal trackers, SlaProjectTracker.where(project_id: @project.id).pluck(:id)
  end

  test "disable_module! purges the cache" do
    @project.disable_module!(:sla)

    assert_not SlaCache.where(project_id: @project.id).exists?
    assert_not SlaCacheSpent.where(project_id: @project.id).exists?
  end

  test "disabling another module keeps the cache" do
    @project.disable_module!(:time_tracking)

    assert SlaCache.where(project_id: @project.id).exists?
  end

  test "nothing is calculated while the module is disabled" do
    @project.disable_module!(:sla)
    issue = Issue.find(@issue.id)

    assert_nil issue.get_sla_level
    assert_nil issue.get_sla_term(1)
    assert_nil issue.get_sla_spent(1)
    assert_nil issue.get_sla_respect(1)
    assert_not SlaCache.where(issue_id: issue.id).exists?
  end

  test "a cache left behind is ignored and cleared once the module is disabled" do
    # Bypass the Project patch, as a direct SQL change to enabled_modules would.
    EnabledModule.where(project_id: @project.id, name: 'sla').delete_all
    assert SlaCache.where(issue_id: @issue.id).exists?

    assert_nil Issue.find(@issue.id).get_sla_level
    assert_not SlaCache.where(issue_id: @issue.id).exists?
  end

  test "explanation lists no SLA level while the module is disabled" do
    assert RedmineSla::SlaExplanation.new(@issue).levels.any? { |row| row['selected'] }
    @project.disable_module!(:sla)

    explanation = RedmineSla::SlaExplanation.new(Issue.find(@issue.id))
    assert_empty explanation.levels
    assert_empty explanation.spent(1)
  end

  test "re-enabling the module calculates again from the kept configuration" do
    expected_level_id = @issue.get_sla_level.id
    @project.disable_module!(:sla)
    @project.reload.enable_module!(:sla)

    issue = Issue.find(@issue.id)
    assert_equal expected_level_id, issue.get_sla_level&.id
    assert_not_nil issue.get_sla_spent(1)
  end
end
