# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

# File: redmine_sla/test/functional/sla_project_trackers_controller_test.rb
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

require_relative "../application_sla_functionals_test_case"

# SlaProjectTrackersController has no require_admin.
# Access is controlled by authorize_global → :manage_sla permission.
# Admin (user 1) and Manager (user 2) both have manage_sla → success.
# Developer, SysAdmin, Reporter, Other → 403.
class SlaProjectTrackersControllerTest < ApplicationSlaFunctionalsTestCase

  def setup
    super
    User.current = nil
    set_language_if_valid 'en'
    @sla_project_tracker = SlaProjectTracker.first  # project_id:1, tracker_id:1, sla_id:1
  end

  # tracker_id:2 is not assigned to project 1 in fixtures → valid new combination.
  def valid_create_params
    { project_id: 1, tracker_id: 2, sla_id: 1 }
  end

  test "should sort project trackers by associated columns and count all results" do
    @request.session[:user_id] = 1
    %w[project tracker sla].each do |column|
      get :index, params: { sort: "#{column}:asc", per_page: 100 }
      assert_response :success
      entities = @controller.instance_variable_get(:@entities)
      assert_equal SlaProjectTracker.count, @controller.instance_variable_get(:@entity_count)
      values = entities.map { |record| column == 'tracker' ? record.tracker.position : record.public_send(column).name }
      assert_equal values.sort, values
    end
  end

  ### As anonymous ###

  test "should redirect on get index as anonymous" do
    with_settings :default_language => "en" do
      get :index
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}
    end
  end

  test "should redirect on get new as anonymous" do
    with_settings :default_language => "en" do
      get :new
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}
    end
  end

  test "should redirect on post create as anonymous" do
    with_settings :default_language => "en" do
      post :create, params: { sla_project_tracker: valid_create_params }
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}
    end
  end

  test "should redirect on get edit as anonymous" do
    with_settings :default_language => "en" do
      get :edit, params: { id: @sla_project_tracker.id }
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}
    end
  end

  test "should redirect on patch update as anonymous" do
    with_settings :default_language => "en" do
      patch :update, params: { id: @sla_project_tracker.id, sla_project_tracker: { sla_id: 1 } }
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}
    end
  end

  test "should redirect on delete destroy as anonymous" do
    with_settings :default_language => "en" do
      delete :destroy, params: { id: @sla_project_tracker.id }
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}
    end
  end

  test "should redirect on get context_menu as anonymous" do
    with_settings :default_language => "en" do
      get :context_menu, params: { ids: [@sla_project_tracker.id] }
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}
    end
  end

  ### As admin #1 ###

  test "should success on get index as admin" do
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      get :index
      assert_response :success
    end
  end

  test "should success on get new as admin" do
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      get :new
      assert_response :success
    end
  end

  test "should redirect on post create as admin" do
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      post :create, params: { sla_project_tracker: valid_create_params }
      assert_response :redirect
      assert_redirected_to sla_project_trackers_path
    end
  end

  test "should success on get edit as admin" do
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      get :edit, params: { id: @sla_project_tracker.id }
      assert_response :success
    end
  end

  test "should redirect on patch update as admin" do
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      patch :update, params: { id: @sla_project_tracker.id, sla_project_tracker: { sla_id: 1 } }
      assert_response :redirect
      assert_redirected_to sla_project_trackers_path
    end
  end

  test "should redirect on delete destroy as admin" do
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      delete :destroy, params: { id: @sla_project_tracker.id }
      assert_response :redirect
      assert_redirected_to sla_project_trackers_path
    end
  end

  test "should success on get context_menu as admin" do
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      get :context_menu, params: { ids: [@sla_project_tracker.id] }
      assert_response :success
    end
  end

  ### As manager #2 (has manage_sla → same as admin for this controller) ###

  test "should success on get index as manager" do
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      get :index
      assert_response :success
    end
  end

  test "should success on get new as manager" do
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      get :new
      assert_response :success
    end
  end

  test "should redirect on post create as manager" do
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      post :create, params: { sla_project_tracker: valid_create_params }
      assert_response :redirect
    end
  end

  test "should success on get edit as manager" do
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      get :edit, params: { id: @sla_project_tracker.id }
      assert_response :success
    end
  end

  test "should redirect on patch update as manager" do
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      patch :update, params: { id: @sla_project_tracker.id, sla_project_tracker: { sla_id: 1 } }
      assert_response :redirect
    end
  end

  test "should redirect on delete destroy as manager" do
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      delete :destroy, params: { id: @sla_project_tracker.id }
      assert_response :redirect
    end
  end

  test "should success on get context_menu as manager" do
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      get :context_menu, params: { ids: [@sla_project_tracker.id] }
      assert_response :success
    end
  end

  ### As developer #3 (no manage_sla → 403) ###

  test "should forbidden on get index as developer" do
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      get :index
      assert_response :forbidden
    end
  end

  test "should forbidden on get new as developer" do
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      get :new
      assert_response :forbidden
    end
  end

  test "should forbidden on post create as developer" do
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      post :create, params: { sla_project_tracker: valid_create_params }
      assert_response :forbidden
    end
  end

  test "should forbidden on get edit as developer" do
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      get :edit, params: { id: @sla_project_tracker.id }
      assert_response :forbidden
    end
  end

  test "should forbidden on patch update as developer" do
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      patch :update, params: { id: @sla_project_tracker.id, sla_project_tracker: { sla_id: 1 } }
      assert_response :forbidden
    end
  end

  test "should forbidden on delete destroy as developer" do
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      delete :destroy, params: { id: @sla_project_tracker.id }
      assert_response :forbidden
    end
  end

  test "should forbidden on get context_menu as developer" do
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      get :context_menu, params: { ids: [@sla_project_tracker.id] }
      assert_response :forbidden
    end
  end

  ### As sysadmin #4 ###

  test "should forbidden on get index as sysadmin" do
    @request.session[:user_id] = 4
    with_settings :default_language => "en" do
      get :index
      assert_response :forbidden
    end
  end

  test "should forbidden on get edit as sysadmin" do
    @request.session[:user_id] = 4
    with_settings :default_language => "en" do
      get :edit, params: { id: @sla_project_tracker.id }
      assert_response :forbidden
    end
  end

  ### As reporter #5 ###

  test "should forbidden on get index as reporter" do
    @request.session[:user_id] = 5
    with_settings :default_language => "en" do
      get :index
      assert_response :forbidden
    end
  end

  ### As other #6 ###

  test "should forbidden on get index as other" do
    @request.session[:user_id] = 6
    with_settings :default_language => "en" do
      get :index
      assert_response :forbidden
    end
  end

  test "manager cannot create a tracker assignment in an unauthorized project" do
    restrict_manager_to_project_one
    assert_no_difference 'SlaProjectTracker.count' do
      post :create, params: {sla_project_tracker: {project_id: 2, tracker_id: 1, sla_id: 1}}
    end
    assert_response :forbidden
  end

  test "manager cannot move an allowed tracker assignment to an unauthorized project" do
    restrict_manager_to_project_one
    link = SlaProjectTracker.find_by!(project_id: 1, tracker_id: 1)
    patch :update, params: {id: link.id, sla_project_tracker: {project_id: 2}}
    assert_response :forbidden
    assert_equal 1, link.reload.project_id
  end

  test "restricted manager only sees manageable projects in the assignment form" do
    restrict_manager_to_project_one
    get :new
    assert_response :success
    assert_select 'select[name="sla_project_tracker[project_id]"] option' do |options|
      assert_equal [1], options.map { |option| option['value'].to_i }.reject(&:zero?)
    end
  end

  test "restricted manager cannot open the assignment form in another project" do
    restrict_manager_to_project_one
    get :new, params: {project_id: 2}
    assert_response :forbidden
  end

  test "project context cannot move or delete an assignment from another project" do
    @request.session[:user_id] = 1
    link = SlaProjectTracker.find_by!(project_id: 1, tracker_id: 1)
    patch :update, params: {project_id: 2, id: link.id, sla_project_tracker: {sla_id: 1}}
    assert_response :forbidden
    assert_equal 1, link.reload.project_id
    assert_no_difference 'SlaProjectTracker.count' do
      delete :destroy, params: {project_id: 2, id: link.id}
    end
    assert_response :forbidden
  end

  test "mixed project bulk deletion is rejected atomically for a restricted manager" do
    restrict_manager_to_project_one
    ids = [SlaProjectTracker.find_by!(project_id: 1).id, SlaProjectTracker.find_by!(project_id: 2).id]
    assert_no_difference 'SlaProjectTracker.count' do
      delete :destroy, params: {ids: ids}
    end
    assert_response :not_found
    assert_equal 2, SlaProjectTracker.where(id: ids).count
  end

  ### Project context (/projects/:project_id/sla/trackers) ###

  test "manager lists only the assignments of the project in project context" do
    @request.session[:user_id] = 2
    get :index, params: { project_id: 1 }
    assert_response :success
    project_ids = @controller.instance_variable_get(:@entities).map(&:project_id)
    assert_equal SlaProjectTracker.where(project_id: 1).count, project_ids.size
    assert_equal [1], project_ids.uniq
    # SLA names stay in the filter and form choices: assert on the rows.
    assert_rendered_assignment_ids SlaProjectTracker.where(project_id: 1).pluck(:id)
  end

  test "manager creates an assignment in the project given by the route" do
    @request.session[:user_id] = 2
    assert_difference 'SlaProjectTracker.count', 1 do
      post :create, params: { project_id: 1, sla_project_tracker: { project_id: 2, tracker_id: 2, sla_id: 1 } }
    end
    assert_redirected_to settings_project_path(Project.find(1), tab: :sla)
    assert SlaProjectTracker.exists?(project_id: 1, tracker_id: 2, sla_id: 1)
    assert_not SlaProjectTracker.exists?(project_id: 2, tracker_id: 2)
  end

  test "manager updates an assignment of the project in project context" do
    @request.session[:user_id] = 2
    patch :update, params: { project_id: 1, id: @sla_project_tracker.id, sla_project_tracker: { sla_id: 2 } }
    assert_redirected_to settings_project_path(Project.find(1), tab: :sla)
    assert_equal 2, @sla_project_tracker.reload.sla_id
  end

  test "manager destroys an assignment of the project in project context" do
    @request.session[:user_id] = 2
    assert_difference 'SlaProjectTracker.count', -1 do
      delete :destroy, params: { project_id: 1, id: @sla_project_tracker.id }
    end
    assert_redirected_to settings_project_path(Project.find(1), tab: :sla)
    assert_not SlaProjectTracker.exists?(@sla_project_tracker.id)
  end

  # Logins without :manage_sla on project 1: view_sla only, member without
  # SLA permission, non-member, member of other projects only.
  { 'developer' => :forbidden, 'reporter' => :forbidden,
    'other' => :forbidden, 'sysadmin' => :forbidden }.each do |login, status|
    test "#{login} is denied every project tracker action in project context" do
      @request.session[:user_id] = User.find_by_login!(login).id
      assert_project_tracker_actions_denied(project_id: 1, status: status)
    end
  end

  test "anonymous is redirected from every project tracker action on a private project" do
    assert_not Project.find(1).is_public?
    assert_project_tracker_actions_denied(project_id: 1, status: :redirect)
  end

  test "anonymous and non-members are denied on a public project" do
    Project.find(1).update_column(:is_public, true)
    [Role.anonymous, Role.non_member].each { |role| role.add_permission!(:view_issues) }
    with_settings login_required: '0' do
      assert_project_tracker_actions_denied(project_id: 1, status: :redirect)
      @request.session[:user_id] = User.find_by_login!('other').id
      assert_project_tracker_actions_denied(project_id: 1, status: :forbidden)
    end
  end

  test "manager and administrator are denied when the SLA module is disabled" do
    Project.find(1).disable_module!(:sla)
    [2, 1].each do |user_id|
      @request.session[:user_id] = user_id
      assert_project_tracker_actions_denied(project_id: 1, status: :forbidden)
    end
  end

  { Project::STATUS_ARCHIVED => 'archived', Project::STATUS_CLOSED => 'closed' }.each do |status, label|
    test "manager is denied project tracker changes on a #{label} project" do
      Project.find(1).update_column(:status, status)
      @request.session[:user_id] = 2
      assert_project_tracker_actions_denied(project_id: 1, status: :forbidden)
    end
  end

  ### Global routes, member of another project ###

  test "restricted manager can change assignments of the managed project" do
    restrict_manager_to_project_one
    assert_difference 'SlaProjectTracker.count', 1 do
      post :create, params: { sla_project_tracker: valid_create_params }
    end
    patch :update, params: { id: @sla_project_tracker.id, sla_project_tracker: { sla_id: 2 } }
    assert_equal 2, @sla_project_tracker.reload.sla_id
    assert_difference 'SlaProjectTracker.count', -1 do
      delete :destroy, params: { id: @sla_project_tracker.id }
    end
  end

  test "restricted manager cannot read, change or delete an assignment of another project" do
    restrict_manager_to_project_one
    link = SlaProjectTracker.find_by!(project_id: 2, tracker_id: 4)
    assert_project_tracker_rows_unchanged do
      get :edit, params: { id: link.id }
      assert_response :not_found
      assert_body_excludes link.sla.name
      patch :update, params: { id: link.id, sla_project_tracker: { sla_id: 1 } }
      assert_response :not_found
      delete :destroy, params: { id: link.id }
      assert_response :not_found
      get :context_menu, params: { ids: [link.id] }
      assert_response :not_found
    end
  end

  test "restricted manager global list hides assignments of other projects" do
    restrict_manager_to_project_one
    get :index, params: { per_page: 100 }
    assert_response :success
    project_ids = @controller.instance_variable_get(:@entities).map(&:project_id)
    assert_equal SlaProjectTracker.where(project_id: 1).count, project_ids.size
    assert_equal [1], project_ids.uniq
    assert_rendered_assignment_ids SlaProjectTracker.where(project_id: 1).pluck(:id)
  end

  test "view_sla member of every project is denied global changes" do
    @request.session[:user_id] = 3
    assert User.find(3).allowed_to?(:view_sla, Project.find(1))
    assert_project_tracker_rows_unchanged do
      post :create, params: { sla_project_tracker: valid_create_params }
      assert_response :forbidden
      patch :update, params: { id: @sla_project_tracker.id, sla_project_tracker: { sla_id: 2 } }
      assert_response :forbidden
      delete :destroy, params: { id: @sla_project_tracker.id }
      assert_response :forbidden
    end
  end

  private

  # Every read and write action, in project context, must be refused with
  # the given status and leave every assignment untouched.
  def assert_project_tracker_actions_denied(project_id:, status:)
    link = SlaProjectTracker.find_by!(project_id: project_id, tracker_id: 1)
    assert_project_tracker_rows_unchanged do
      [
        -> { get :index, params: { project_id: project_id } },
        -> { get :new, params: { project_id: project_id } },
        -> { get :edit, params: { project_id: project_id, id: link.id } },
        -> { get :context_menu, params: { project_id: project_id, ids: [link.id] } },
        -> { post :create, params: { project_id: project_id, sla_project_tracker: { tracker_id: 2, sla_id: 1 } } },
        -> { patch :update, params: { project_id: project_id, id: link.id, sla_project_tracker: { sla_id: 2 } } },
        -> { delete :destroy, params: { project_id: project_id, id: link.id } }
      ].each do |request_action|
        request_action.call
        assert_response status
        assert_body_excludes link.sla.name if status == :forbidden
      end
    end
  end

  # Keeps failure messages short instead of dumping the whole page.
  def assert_body_excludes(text)
    assert_not response.body.include?(text), "response body exposes #{text.inspect}"
  end

  def assert_rendered_assignment_ids(expected_ids)
    rendered_ids = css_select('tr.entity[id^="entity_id_"]').map { |row| row['id'].delete_prefix('entity_id_').to_i }
    assert_not_empty expected_ids
    assert_equal expected_ids.sort, rendered_ids.sort
  end

  def assert_project_tracker_rows_unchanged
    snapshot = -> { SlaProjectTracker.order(:id).pluck(:id, :project_id, :tracker_id, :sla_id) }
    before = snapshot.call
    assert_not_empty before
    yield
    assert_equal before, snapshot.call
  end

  def restrict_manager_to_project_one
    Member.where(user_id: 2).where.not(project_id: 1).destroy_all
    @request.session[:user_id] = 2
    manager = User.find(2)
    assert manager.allowed_to?(:manage_sla, Project.find(1))
    assert_not manager.allowed_to?(:manage_sla, Project.find(2))
  end

end
