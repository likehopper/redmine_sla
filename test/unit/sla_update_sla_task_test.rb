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

# File: redmine_sla/test/unit/sla_update_sla_task_test.rb
# Purpose:
#   Cover the projects and scope options of the update_sla task, and the
#   handling of projects without the SLA module or not active.
#
# Redmine SLA - Redmine's Plugin

require File.expand_path('../../application_sla_units_test_case', __FILE__)

class SlaUpdateSlaTaskTest < ApplicationSlaUnitsTestCase
  def setup
    @project = Project.find(1)
    # Closed fixture issues are settled by the test bootstrap run.
    @open_issue = Issue.find(4)
    @open_issue.update_columns(status_id: IssueStatus.where(is_closed: false).order(:id).first.id)
    @closed_issue_ids = SlaCacheSpent.joins(issue: :status).where(project_id: @project.id, issue_statuses: { is_closed: true })
                                     .where.not(issue_id: @open_issue.id).distinct.order(:issue_id).pluck(:issue_id)
    @closed_issue_id = @closed_issue_ids.first
    assert_not_nil @closed_issue_id
  end

  ### projects ###

  test "purges by default the cache left on projects without the module" do
    other_project_ids = SlaCache.where.not(project_id: @project.id).distinct.pluck(:project_id)
    assert_not_empty other_project_ids
    disable_sla_module_directly

    run_update_sla

    assert_not SlaCache.where(project_id: @project.id).exists?
    assert_equal other_project_ids.sort, SlaCache.distinct.pluck(:project_id).sort
  end

  test "projects=without_sla only purges projects without the module" do
    disable_sla_module_directly
    other_cache = SlaCache.where.not(project_id: @project.id).first
    SlaCache.where(id: other_cache.id).delete_all

    run_update_sla('projects' => 'without_sla')

    assert_not SlaCache.where(project_id: @project.id).exists?
    assert_not SlaCache.where(id: other_cache.id).exists?
  end

  test "projects=with_sla leaves projects without the module untouched" do
    disable_sla_module_directly

    run_update_sla('projects' => 'with_sla')

    assert SlaCache.where(project_id: @project.id).exists?
  end

  test "rejects an unknown projects option" do
    assert_raises(SystemExit) { run_update_sla('projects' => 'unknown') }
  end

  test "keeps the cache of a project not active as is" do
    @project.update_columns(status: Project::STATUS_CLOSED)
    SlaCache.where(issue_id: @closed_issue_id).delete_all
    cache_ids = SlaCache.where(project_id: @project.id).order(:id).pluck(:id)
    assert_not_empty cache_ids

    processed = run_update_sla('scope' => 'all')

    assert_empty processed & @project.issue_ids
    assert_equal cache_ids, SlaCache.where(project_id: @project.id).order(:id).pluck(:id)
  end

  ### scope ###

  test "scope defaults to open issues and closed issues not updated since closing" do
    SlaCache.where(issue_id: @closed_issue_id).delete_all
    settled_issue_id = @closed_issue_ids.second

    processed = run_update_sla

    assert_includes processed, @open_issue.id
    assert_includes processed, @closed_issue_id
    assert_not_includes processed, settled_issue_id
    assert SlaCacheSpent.where(issue_id: @closed_issue_id).exists?
  end

  test "scope=miss only processes issues without SLA cache" do
    SlaCache.where(issue_id: @closed_issue_id).delete_all

    processed = run_update_sla('scope' => 'miss')

    assert_includes processed, @closed_issue_id
    assert_not_includes processed, @open_issue.id
    assert SlaCache.where(issue_id: @closed_issue_id).exists?
  end

  test "scope=all processes closed issues already updated" do
    processed = run_update_sla('scope' => 'all')

    assert_includes processed, @open_issue.id
    assert_includes processed, @closed_issue_id
  end

  test "rejects an unknown scope option" do
    assert_raises(SystemExit) { run_update_sla('scope' => 'unknown') }
  end

  private

  # Bypass the Project patch, as a direct SQL change to enabled_modules would.
  def disable_sla_module_directly
    EnabledModule.where(project_id: @project.id, name: 'sla').delete_all
  end

  # Runs the task and returns the ids of the issues it processed.
  def run_update_sla(env = {})
    # The task itself: its update_sla alias already ran in the test bootstrap.
    task = Rake::Task['sla:update']
    saved = env.keys.to_h { |key| [key, ENV[key]] }
    env.each { |key, value| ENV[key] = value }
    task.reenable
    out, _err = capture_io { task.invoke }
    out.scan(/^\t#(\d+) /).flatten.map(&:to_i)
  ensure
    saved&.each { |key, value| ENV[key] = value }
  end
end
