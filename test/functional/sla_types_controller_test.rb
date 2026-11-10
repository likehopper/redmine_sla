# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

# File: redmine_sla/test/functional/sla_types_controller_test.rb
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

class SlaTypesControllerTest < ApplicationSlaFunctionalsTestCase

  def setup
    super
    User.current = nil
    set_language_if_valid 'en'
  end

  ### As anonymous ###

  test "should get 302 on get index as anonymous" do
    with_settings :default_language => "en" do
      get :index
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}
    end
  end

  test "should get 302 on get new as anonymous" do
    with_settings :default_language => "en" do
      get :new
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}
    end
  end  

  test "should get 302 on post create as anonymous" do
    with_settings :default_language => "en" do
      post(:create, :params => {:name => "SLA Type test"})
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}
    end
  end  

  test "should get 302 on get edit as anonymous" do
    with_settings :default_language => "en" do
      get(:edit, :params => {:id => 1})
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}
    end
  end

  test "should return 403 on patch update as anonymous" do
    with_settings :default_language => "en" do
      put :update, params: { id: 1, sla: { name: "SLA Type test change" } }
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}
      patch :update, params: { id: 1, sla: { name: "SLA Type test change" } }
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}   
    end
  end 

  test "should get 302 on delete destroy as anonymous" do
    with_settings :default_language => "en" do
      delete(:destroy, :params => {:id => 1})
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}
    end
  end  

  ### As admin #1 ###

  test "should get success on index as admin" do
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      get :index
      assert_response :success
      # links to visible issues
      assert_select 'a[href="/sla/types/1"]', :title => "Show"
      assert_select 'a[href="/sla/types/1/edit"]', :title => "Edit"
      assert_select 'a[href="/sla/types/1"]', :title => "Delete", :method => "delete"
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

  test "should reorder via format.js as admin" do
    @request.session[:user_id] = 1
    put :update, params: { id: 1, sla_type: { position: 2 }, format: :js }
    assert_response :success
    assert_equal 2, SlaType.find(1).position
  end

  test "should return 422 on format.js with invalid data as admin" do
    @request.session[:user_id] = 1
    put :update, params: { id: 1, sla_type: { name: "" }, format: :js }
    assert_response 422
  end

  test "should list sla types ordered by position on index" do
    @request.session[:user_id] = 1
    SlaType.find(2).update!(position: 1)
    SlaType.find(1).update!(position: 2)

    get :index
    assert_response :success
    assert_operator response.body.index('GTR'), :<, response.body.index('GTI')
  end

  test "should show reorder handles on the natural (unfiltered, position-sorted) index" do
    @request.session[:user_id] = 1
    get :index
    assert_response :success
    assert_select '.sort-handle', count: SlaType.count
  end

  test "should hide reorder handles when a name filter is active" do
    @request.session[:user_id] = 1
    get :index, params: { set_filter: 1, f: ['name'], op: { 'name' => '=' }, v: { 'name' => ['GTI'] } }
    assert_response :success
    assert_select '.sort-handle', count: 0
  end

  test "should hide reorder handles when sorted by a column other than position" do
    @request.session[:user_id] = 1
    get :index, params: { sort: 'name' }
    assert_response :success
    assert_select '.sort-handle', count: 0
  end

  ### As manager #2 ###

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
      assert_response 403
    end
  end

  test "should return 403 on get edit as manager" do
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      get(:edit, :params => {:id => 1})
      assert_response 403
    end
  end

  ### As developper #3 ###

  test "should return 403 on get index as developper" do
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      get :index
      assert_response 403
    end
  end

  test "should return 403 on get show as developper" do
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      get(:show, :params => {:id => 1})
      assert_response 403
    end
  end

  test "should return 403 on get edit as developper" do
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      get(:edit, :params => {:id => 1})
      assert_response 403
    end
  end

  ### As sysadmin #4 ###

  test "should return 403 on get index as sysadmin" do
    @request.session[:user_id] = 4
    with_settings :default_language => "en" do
      get :index
      assert_response 403
    end
  end

  test "should return 403 on get show as sysadmin" do
    @request.session[:user_id] = 4
    with_settings :default_language => "en" do
      get(:show, :params => {:id => 1})
      assert_response 403
    end
  end

  test "should return 403 on get edit as sysadmin" do
    @request.session[:user_id] = 4
    with_settings :default_language => "en" do
      get(:edit, :params => {:id => 1})
      assert_response 403
    end
  end

  ### As reporter #5 ###

  test "should return 403 on get index as reporter" do
    @request.session[:user_id] = 5
    with_settings :default_language => "en" do
      get :index
      assert_response 403
    end
  end

  test "should return 403 on get show as reporter" do
    @request.session[:user_id] = 5
    with_settings :default_language => "en" do
      get(:show, :params => {:id => 1})
      assert_response 403
    end
  end

  test "should return 403 on get edit as reporter" do
    @request.session[:user_id] = 5
    with_settings :default_language => "en" do
      get(:edit, :params => {:id => 1})
      assert_response 403
    end
  end

  ### As other #6 ###

  test "should return 403 on get index as other" do
    @request.session[:user_id] = 6
    with_settings :default_language => "en" do
      get :index
      assert_response 403
    end
  end

  test "should return 403 on get show as other" do
    @request.session[:user_id] = 6
    with_settings :default_language => "en" do
      get(:show, :params => {:id => 1})
      assert_response 403
    end
  end

  test "should return 403 on get edit as other" do
    @request.session[:user_id] = 6
    with_settings :default_language => "en" do
      get(:edit, :params => {:id => 1})
      assert_response 403
    end
  end  

  ### Access audit: SLA types are managed by administrators only ###

  test "should redirect on get show as anonymous" do
    get :show, params: { id: 1 }
    assert_redirected_to %r{#{signin_path}}
  end

  test "should render new and context menu on SLA types as admin" do
    @request.session[:user_id] = 1
    get :new
    assert_response :success
    get :context_menu, params: { ids: [1] }
    assert_response :success
    assert_select "a[href=?]", edit_sla_type_path(1)
  end

  test "should create, update, delete and bulk delete SLA types as admin" do
    @request.session[:user_id] = 1
    assert_difference "SlaType.count", 1 do
      post :create, params: { sla_type: { name: "Created SLA type" } }
    end
    assert_redirected_to sla_types_path
    patch :update, params: { id: 1, sla_type: { name: "Updated SLA type" } }
    assert_redirected_to sla_types_path
    assert_equal "Updated SLA type", SlaType.find(1).name
    deletables = create_deletable_sla_types
    assert_difference "SlaType.count", -1 do
      delete :destroy, params: { id: deletables.first.id }
    end
    assert_difference "SlaType.count", -2 do
      delete :destroy, params: { ids: deletables.drop(1).map(&:id) }
    end
    assert_redirected_to sla_types_path
  end

  { "anonymous" => nil, "project SLA manager" => 2, "reporter without SLA permission" => 5 }.each do |label, user_id|
    test "should deny new and context menu on SLA types to #{label}" do
      @request.session[:user_id] = user_id
      get :new
      assert_access_denied(user_id)
      get :context_menu, params: { ids: [1] }
      assert_access_denied(user_id)
    end

    test "should deny SLA type writes to #{label} without changing data" do
      deletables = create_deletable_sla_types
      assert_denied_without_change(user_id, SlaType.find(1)) do
        post :create, params: { sla_type: { name: "Denied SLA type" } }
        assert_access_denied(user_id)
        patch :update, params: { id: 1, sla_type: { name: "Denied SLA type change", position: 2 } }
        assert_access_denied(user_id)
        delete :destroy, params: { id: deletables.first.id }
        assert_access_denied(user_id)
        delete :destroy, params: { ids: deletables.map(&:id) }
        assert_access_denied(user_id)
      end
      assert_equal deletables.size, SlaType.where(id: deletables.map(&:id)).count
    end
  end

  # Fresh types without terms or statuses, so a leaked destroy would really delete them.
  def create_deletable_sla_types
    Array.new(3) { |index| SlaType.create!(name: "Deletable SLA type #{index}") }
  end

end
