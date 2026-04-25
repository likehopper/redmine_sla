# frozen_string_literal: true

# File: redmine_sla/test/functional/sla_schedules_controller_test.rb
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

# SlaSchedulesController requires admin for ALL actions (before_action :require_admin).
# Non-admin authenticated users always receive 403.
class SlaSchedulesControllerTest < ApplicationSlaFunctionalsTestCase

  def setup
    super
    User.current = nil
    set_language_if_valid 'en'
    @sla_schedule = SlaSchedule.first
  end

  # Valid params for create: dow=0 (Sunday) on calendar 1 is not in fixtures.
  def valid_create_params
    { sla_calendar_id: 1, dow: 0, start_time: "10:00", end_time: "17:00", match: "1" }
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
      post :create, params: { sla_schedule: valid_create_params }
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}
    end
  end

  test "should redirect on get show as anonymous" do
    with_settings :default_language => "en" do
      get :show, params: { id: @sla_schedule.id }
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}
    end
  end

  test "should redirect on get edit as anonymous" do
    with_settings :default_language => "en" do
      get :edit, params: { id: @sla_schedule.id }
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}
    end
  end

  test "should redirect on patch update as anonymous" do
    with_settings :default_language => "en" do
      patch :update, params: { id: @sla_schedule.id, sla_schedule: { match: "0" } }
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}
    end
  end

  test "should redirect on delete destroy as anonymous" do
    with_settings :default_language => "en" do
      delete :destroy, params: { id: @sla_schedule.id }
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}
    end
  end

  test "should redirect on get context_menu as anonymous" do
    with_settings :default_language => "en" do
      get :context_menu, params: { ids: [@sla_schedule.id] }
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}
    end
  end

  ### As admin #1 (require_admin passes) ###

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
      post :create, params: { sla_schedule: valid_create_params }
      assert_response :redirect
      assert_redirected_to sla_schedules_path
    end
  end

  test "should success on get show as admin" do
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      get :show, params: { id: @sla_schedule.id }
      assert_response :success
    end
  end

  test "should success on get edit as admin" do
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      get :edit, params: { id: @sla_schedule.id }
      assert_response :success
    end
  end

  test "should redirect on patch update as admin" do
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      patch :update, params: { id: @sla_schedule.id, sla_schedule: { match: "0" } }
      assert_response :redirect
      assert_redirected_to sla_schedules_path
    end
  end

  test "should redirect on delete destroy as admin" do
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      delete :destroy, params: { id: @sla_schedule.id }
      assert_response :redirect
      assert_redirected_to sla_schedules_path
    end
  end

  test "should success on get context_menu as admin" do
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      get :context_menu, params: { ids: [@sla_schedule.id] }
      assert_response :success
    end
  end

  ### As manager #2 (not admin → 403 on all actions) ###

  test "should forbidden on get index as manager" do
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      get :index
      assert_response :forbidden
    end
  end

  test "should forbidden on get new as manager" do
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      get :new
      assert_response :forbidden
    end
  end

  test "should forbidden on post create as manager" do
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      post :create, params: { sla_schedule: valid_create_params }
      assert_response :forbidden
    end
  end

  test "should forbidden on get edit as manager" do
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      get :edit, params: { id: @sla_schedule.id }
      assert_response :forbidden
    end
  end

  test "should forbidden on patch update as manager" do
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      patch :update, params: { id: @sla_schedule.id, sla_schedule: { match: "0" } }
      assert_response :forbidden
    end
  end

  test "should forbidden on delete destroy as manager" do
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      delete :destroy, params: { id: @sla_schedule.id }
      assert_response :forbidden
    end
  end

  test "should forbidden on get context_menu as manager" do
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      get :context_menu, params: { ids: [@sla_schedule.id] }
      assert_response :forbidden
    end
  end

  ### As developer #3 ###

  test "should forbidden on get index as developer" do
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      get :index
      assert_response :forbidden
    end
  end

  test "should forbidden on get edit as developer" do
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      get :edit, params: { id: @sla_schedule.id }
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

end
