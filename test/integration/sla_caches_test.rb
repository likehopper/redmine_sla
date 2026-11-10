# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

# File: redmine_sla/test/integration/sla_caches_test.rb
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

require_relative "../application_sla_integration_test_case"

# End-to-end check of the "Explain" feature through the real routing table
# and a real session login (unlike the functional tests, which dispatch
# straight to the controller action).
class SlaCachesTest < ApplicationSlaIntegrationTestCase

  def setup
    User.current = nil
    set_language_if_valid 'en'
  end

  test "should return success on get sla_explain as manager" do
    log_user('manager', 'manager')
    issue_id = SlaCache.where(project: 1).order(:id).first.issue_id
    get "/issues/#{issue_id}/sla_explain"
    assert_response :success
  end

  test "should return forbidden on get sla_explain as developer with view_sla only" do
    log_user('developer', 'developer')
    issue_id = SlaCache.where(project: 1).order(:id).first.issue_id
    get "/issues/#{issue_id}/sla_explain"
    assert_response :forbidden
    assert_explanation_hidden
  end

  test "sla_explain shows the applicable level name to a manager" do
    log_user('manager', 'manager')
    get "/issues/#{explained_issue.id}/sla_explain"
    assert_response :success
    assert_select 'td', text: explained_level.name
  end

  test "sla_explain redirects anonymous users to the login page" do
    get "/issues/#{explained_issue.id}/sla_explain"
    assert_response :redirect
    assert_match %r{/login}, response.location

    explained_issue.project.update_column(:is_public, true)
    Role.anonymous.add_permission!(:view_issues)
    with_settings login_required: '0' do
      get "/issues/#{explained_issue.id}"
      assert_response :success
      get "/issues/#{explained_issue.id}/sla_explain"
      assert_response :redirect
      assert_match %r{/login}, response.location
    end
  end

  test "sla_explain is forbidden to members without manage_sla and to non-members" do
    explained_issue.project.update_column(:is_public, true)
    Role.non_member.add_permission!(:view_issues)
    # reporter: member without SLA permission; other: non-member of a public
    # project; sysadmin: view_sla in other projects only.
    %w[reporter other sysadmin].each do |login|
      reset!
      log_user(login, login)
      get "/issues/#{explained_issue.id}"
      assert_response :success
      get "/issues/#{explained_issue.id}/sla_explain"
      assert_response :forbidden
      assert_explanation_hidden
    end
  end

  test "sla_explain is forbidden to a manager when the SLA module is disabled" do
    explained_issue.project.disable_module!(:sla)
    log_user('manager', 'manager')
    get "/issues/#{explained_issue.id}/sla_explain"
    assert_response :forbidden
    assert_explanation_hidden
  end

  test "sla_explain is forbidden to a manager of another project who can view the issue" do
    restrict_manager_to_project_two
    Member.create!(project: explained_issue.project, principal: User.find_by_login!('manager'), role_ids: [3])
    log_user('manager', 'manager')
    get "/issues/#{explained_issue.id}"
    assert_response :success
    get "/issues/#{explained_issue.id}/sla_explain"
    assert_response :forbidden
    assert_explanation_hidden
  end

  test "sla_explain hides issues of a project the manager is not a member of" do
    restrict_manager_to_project_two
    log_user('manager', 'manager')
    get "/issues/#{explained_issue.id}/sla_explain"
    assert_response :not_found
    assert_explanation_hidden
  end

  test "sla_explain hides issues of an archived project" do
    explained_issue.project.update_column(:status, Project::STATUS_ARCHIVED)
    log_user('manager', 'manager')
    get "/issues/#{explained_issue.id}/sla_explain"
    assert_response :not_found
    assert_explanation_hidden
  end

  private

  def explained_issue
    @explained_issue ||= Issue.find(SlaCache.find_by!(project_id: 1, sla_level_id: 1).issue_id)
  end

  def explained_level
    SlaLevel.find(1)
  end

  def assert_explanation_hidden
    assert_not response.body.include?(explained_level.name), 'response exposes the SLA level'
  end

  # The manager keeps manage_sla in project 2 only.
  def restrict_manager_to_project_two
    manager = User.find_by_login!('manager')
    Member.where(user_id: manager.id).where.not(project_id: 2).destroy_all
    assert manager.reload.allowed_to?(:manage_sla, Project.find(2))
    assert_not manager.allowed_to?(:view_issues, explained_issue.project)
  end

end
