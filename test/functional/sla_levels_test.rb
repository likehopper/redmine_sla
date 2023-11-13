# frozen_string_literal: true

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

require File.expand_path('../../test_helper', __FILE__)

class SlaLevelsControllerTest < Redmine::ControllerTest

  fixtures \
    :users,
    :email_addresses,
    :roles,
    :enumerations,
    :issue_statuses,
    :trackers,
    :workflows,
    :slas,
    :sla_calendars,
    :sla_holidays,
    :sla_calendar_holidays,
    :sla_schedules,
    :sla_types,
    :sla_levels,
    :sla_level_terms,
    :sla_statuses,
    :projects,
    :members,
    :member_roles,
    :projects_trackers,
    :sla_project_trackers,
    :enabled_modules,
    :issues,
    :journals,
    :journal_details

  include Redmine::I18n

  def setup
    User.current = nil
    set_language_if_valid 'en'
  end

  ### As anonymous ###

  test "should get 302 on index as anonymous" do
    with_settings :default_language => "en" do
      get :index
      assert_response 302
    end
  end

  test "should get 302 on show as anonymous" do
    with_settings :default_language => "en" do
      get(:show, :params => {:id => 1})
      assert_response 302
    end
  end

  test "should get 302 on edit as anonymous" do
    with_settings :default_language => "en" do
      get(:edit, :params => {:id => 1})
      assert_response 302
    end
  end

  ### As admin ###

  test "should get success on index as admin" do
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      get :index
      assert_response :success
      # links to visible issues
      assert_select 'a[href="/sla/levels/1"]', :title => "Show"
      assert_select 'a[href="/sla/levels/1/edit"]', :title => "Edit"
      assert_select 'a[href="/sla/levels/1"]', :title => "Delete", :method => "delete"
    end
  end

  test "should return success on get show as admin" do
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      get(:show, :params => {:id => 1})
      assert_response :success
    end
  end

  test "should return success on get edit as admin" do
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      get(:edit, :params => {:id => 1})
      assert_response :success
    end
  end

  ### As manager ###

  test "should return 403 on get index as manager" do
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      get :index
      assert_response 403
    end
  end

  test "should return 403 on get show as manager" do
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      get(:show, :params => {:id => 1})
      assert_response :success
    end
  end

  test "should return 403 on get edit as manager" do
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      get(:edit, :params => {:id => 1})
      assert_response 403
    end
  end

  ### As developper ###

  test "should return 403 on get index as developper" do
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      get :index
      assert_response 403
    end
  end

  test "should return success on get show as developper" do
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      get(:show, :params => {:id => 1})
      assert_response :success
    end
  end

  test "should return 403 on get edit as developper" do
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      get(:edit, :params => {:id => 1})
      assert_response 403
    end
  end

  ### As reporter ###

  test "should return 403 on get index as reporter" do
    @request.session[:user_id] = 4
    with_settings :default_language => "en" do
      get :index
      assert_response 403
    end
  end

  test "should return 403 on get show as reporter" do
    @request.session[:user_id] = 4
    with_settings :default_language => "en" do
      get(:show, :params => {:id => 1})
      assert_response 403
    end
  end

  test "should return 403 on get edit as reporter" do
    @request.session[:user_id] = 4
    with_settings :default_language => "en" do
      get(:edit, :params => {:id => 1})
      assert_response 403
    end
  end

  ### As other ###

  test "should return 403 on get index as other" do
    @request.session[:user_id] = 5
    with_settings :default_language => "en" do
      get :index
      assert_response 403
    end
  end

  test "should return 403 on get show as other" do
    @request.session[:user_id] = 5
    with_settings :default_language => "en" do
      get(:show, :params => {:id => 1})
      assert_response 403
    end
  end

  test "should return 403 on get edit as other" do
    @request.session[:user_id] = 5
    with_settings :default_language => "en" do
      get(:edit, :params => {:id => 1})
      assert_response 403
    end
  end

end