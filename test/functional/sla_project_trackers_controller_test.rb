# frozen_string_literal: true

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

  private

  def restrict_manager_to_project_one
    Member.where(user_id: 2).where.not(project_id: 1).destroy_all
    @request.session[:user_id] = 2
    manager = User.find(2)
    assert manager.allowed_to?(:manage_sla, Project.find(1))
    assert_not manager.allowed_to?(:manage_sla, Project.find(2))
  end

end
