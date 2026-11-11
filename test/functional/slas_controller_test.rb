# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

# File: redmine_sla/test/functional/slas_controller_test.rb
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

class SlasControllerTest < ApplicationSlaFunctionalsTestCase

  def setup
    super
    User.current = nil
    set_language_if_valid 'en'
  end

  ### As anonymous ###

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
      post(:create, :params => {:name => "SLA test"})
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}
    end
  end

  test "should redirect on get show as anonymous" do
    with_settings :default_language => "en" do
      get(:show, :params => {:id => 1})
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}
    end
  end

  test "should redirect on get edit as anonymous" do
    with_settings :default_language => "en" do
      get(:edit, :params => {:id => 1})
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}
    end
  end

  test "should redirect on patch update as anonymous" do
    with_settings :default_language => "en" do
      put :update, params: { id: 1, sla: { name: "SLA test change" } }
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}
      patch :update, params: { id: 1, sla: { name: "SLA test change" } }
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}   
    end
  end 

  test "should redirect on delete destroy as anonymous" do
    with_settings :default_language => "en" do
      delete(:destroy, :params => {:id => 1})
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}
    end
  end  

  ### As admin #1 ###

  test "should success on get index as admin" do
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      get :index
      assert_response :success
      # links to visible issues
      assert_select 'a[href="/sla/slas/1"]', :title => "Show"
      assert_select 'a[href="/sla/slas/1/edit"]', :title => "Edit"
      assert_select 'a[href="/sla/slas/1"]', :title => "Delete", :method => "delete"
    end
  end

  # Regression: a block column (here the description) used to make the list
  # fail with a 500 error, its partial reading an undefined `query`.
  test "should get success on index with the description block column as admin" do
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      get :index, :params => {:set_filter => 1, :c => ['name', 'description']}
      assert_response :success
      # The description row spans the checkbox, name and buttons cells
      assert_select 'tr#entity_id_1 + tr td.description[colspan="3"]',
        :text => /#{Regexp.escape(Sla.find(1).description)}/
    end
  end

  test "should success on get new as admin" do
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      get :new
      assert_response :success      
    end
  end  

  test "should success on post create as admin" do
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      post(:create, :params => { sla: { :name => "SLA test" } } )
      assert_response :redirect 
      assert_redirected_to slas_path     
    end
  end

  test "should success on get show as admin" do
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      get(:show, :params => {:id => 1})
      assert_response :success
      # links to visible issues
      assert_select 'a[href="/sla/slas/1"]', :title => "Show"
      assert_select 'a[href="/sla/slas/1/edit"]', :title => "Edit"
      assert_select 'a[href="/sla/slas/1"]', :title => "Delete", :method => "delete"      
    end
  end

  test "should success on get edit as admin" do
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      get(:edit, :params => {:id => 1})
      assert_response :success
    end
  end

  test "should success on patch update as admin" do
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      put :update, params: { id: 1, sla: { name: "SLA test change" } }
      assert_response :redirect 
      assert_redirected_to slas_path
      patch :update, params: { id: 1, sla: { name: "SLA test change" } }
      assert_response :redirect 
      assert_redirected_to slas_path         
    end
  end  

  test "should redirect on delete destroy as admin" do
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      delete(:destroy, :params => {:id => 1})
      assert_response :redirect
      assert_redirected_to slas_path
    end
  end  

  ### As manager #2 ###

  test "should get scoped index as manager" do
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      get :index
      assert_response :success
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
      post(:create, :params => { sla: { :name => "SLA test" } } )
      assert_response :forbidden
    end
  end

  test "should get visible SLA as manager" do
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      get(:show, :params => {:id => 1})
      assert_response :success
    end
  end

  test "should forbidden on get edit as manager" do
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      get(:edit, :params => {:id => 1})
      assert_response :forbidden
    end
  end
    
  test "should forbidden on patch update as manager" do
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      put :update, params: { id: 1, sla: { name: "SLA test change" } }
      assert_response :forbidden
      patch :update, params: { id: 1, sla: { name: "SLA test change" } }
      assert_response :forbidden      
    end
  end
  
  test "should forbidden on get delete destroy as manager" do
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      delete(:destroy, :params => {:id => 1})
      assert_response :forbidden
    end
  end

  ### As developper #3 ###

  test "should get scoped index as developper" do
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      get :index
      assert_response :success
    end
  end

  test "should forbidden on get new as developper" do
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      get :new
      assert_response :forbidden
    end
  end  

  test "should forbidden on post create as developper" do
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      post(:create, :params => { sla: { :name => "SLA test" } } )
      assert_response :forbidden
    end
  end

  test "should get visible SLA as developper" do
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      get(:show, :params => {:id => 1})
      assert_response :success
    end
  end

  test "should forbidden on get edit as developper" do
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      get(:edit, :params => {:id => 1})
      assert_response :forbidden
    end
  end
 
  test "should forbidden on patch update as developper" do
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      put :update, params: { id: 1, sla: { name: "SLA test change" } }
      assert_response :forbidden
      patch :update, params: { id: 1, sla: { name: "SLA test change" } }
      assert_response :forbidden      
    end
  end

  test "should forbidden on get delete destroy as developper" do
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      delete(:destroy, :params => {:id => 1})
      assert_response :forbidden
    end
  end

  ### As sysadmin #4 ###

  test "should get scoped index as sysadmin" do
    @request.session[:user_id] = 4
    with_settings :default_language => "en" do
      get :index
      assert_response :success
    end
  end

  test "should forbidden on get new as sysadmin" do
    @request.session[:user_id] = 4
    with_settings :default_language => "en" do
      get :new
      assert_response :forbidden
    end
  end

  test "should forbidden on post create as sysadmin" do
    @request.session[:user_id] = 4
    with_settings :default_language => "en" do
      post(:create, :params => { sla: { :name => "SLA test" } } )
      assert_response :forbidden
    end
  end  

  test "should forbidden on get show as sysadmin" do
    @request.session[:user_id] = 4
    with_settings :default_language => "en" do
      get(:show, :params => {:id => 1})
      assert_response :forbidden
    end
  end

  test "should forbidden on get edit as sysadmin" do
    @request.session[:user_id] = 4
    with_settings :default_language => "en" do
      get(:edit, :params => {:id => 1})
      assert_response :forbidden
    end
  end

  test "should forbidden on patch update as sysadmin" do
    @request.session[:user_id] = 4
    with_settings :default_language => "en" do
      put :update, params: { id: 1, sla: { name: "SLA test change" } }
      assert_response :forbidden
      patch :update, params: { id: 1, sla: { name: "SLA test change" } }
      assert_response :forbidden      
    end
  end

  test "should forbidden on get delete destroy as sysadmin" do
    @request.session[:user_id] = 4
    with_settings :default_language => "en" do
      delete(:destroy, :params => {:id => 1})
      assert_response :forbidden
    end
  end  

  ### As reporter #5 ###

  test "should forbidden on get index as reporter" do
    @request.session[:user_id] = 5
    with_settings :default_language => "en" do
      get :index
      assert_response :forbidden
    end
  end

  test "should forbidden on get new as reporter" do
    @request.session[:user_id] = 5
    with_settings :default_language => "en" do
      get :new
      assert_response :forbidden
    end
  end  

  test "should forbidden on post create as reporter" do
    @request.session[:user_id] = 5
    with_settings :default_language => "en" do
      post(:create, :params => { sla: { :name => "SLA test" } } )
      assert_response :forbidden
    end
  end  

  test "should forbidden on get show as reporter" do
    @request.session[:user_id] = 5
    with_settings :default_language => "en" do
      get(:show, :params => {:id => 1})
      assert_response :forbidden
    end
  end

  test "should forbidden on get edit as reporter" do
    @request.session[:user_id] = 5
    with_settings :default_language => "en" do
      get(:edit, :params => {:id => 1})
      assert_response :forbidden
    end
  end

  test "should forbidden on patch update as reporter" do
    @request.session[:user_id] = 5
    with_settings :default_language => "en" do
      put :update, params: { id: 1, sla: { name: "SLA test change" } }
      assert_response :forbidden
      patch :update, params: { id: 1, sla: { name: "SLA test change" } }
      assert_response :forbidden      
    end
  end  

  test "should forbidden on get delete destroy as reporter" do
    @request.session[:user_id] = 5
    with_settings :default_language => "en" do
      delete(:destroy, :params => {:id => 1})
      assert_response :forbidden
    end
  end

  ### As other #6 ###

  test "should forbidden on get index as other" do
    @request.session[:user_id] = 6
    with_settings :default_language => "en" do
      get :index
      assert_response :forbidden
    end
  end

  test "should forbidden on get new as other" do
    @request.session[:user_id] = 6
    with_settings :default_language => "en" do
      get :new
      assert_response :forbidden
    end
  end

  test "should forbidden on post create as other" do
    @request.session[:user_id] = 6
    with_settings :default_language => "en" do
      post(:create, :params => { sla: { :name => "SLA test" } } )
      assert_response :forbidden
    end
  end  

  test "should forbidden on get show as other" do
    @request.session[:user_id] = 6
    with_settings :default_language => "en" do
      get(:show, :params => {:id => 1})
      assert_response :forbidden
    end
  end

  test "should forbidden on get edit as other" do
    @request.session[:user_id] = 6
    with_settings :default_language => "en" do
      get(:edit, :params => {:id => 1})
      assert_response :forbidden
    end
  end

  test "should forbidden on patch update as other" do
    @request.session[:user_id] = 6
    with_settings :default_language => "en" do
      put :update, params: { id: 1, sla: { name: "SLA test change" } }
      assert_response :forbidden
      patch :update, params: { id: 1, sla: { name: "SLA test change" } }
      assert_response :forbidden      
    end
  end  

  test "should forbidden on get delete destroy as other" do
    @request.session[:user_id] = 6
    with_settings :default_language => "en" do
      delete(:destroy, :params => {:id => 1})
      assert_response :forbidden
    end
  end

  test "should scope project index to SLAs used by a Resolver project" do
    @request.session[:user_id] = 3

    get :index, params: {project_id: "project-sla-tests-tma"}

    assert_response :success
    assert_select "#entity_id_1", count: 1
    assert_select "#entity_id_2", count: 1
    assert_select "#entity_id_3", count: 0
    assert_select 'a[href="/projects/project-sla-tests-tma/sla/slas/1"]', title: "Show"
  end

  test "should forbid Resolver access to another project SLA index" do
    @request.session[:user_id] = 3

    get :index, params: {project_id: "project-sla-tests-std"}

    assert_response :forbidden
  end

  test "should forbid showing a SLA outside the requested project" do
    @request.session[:user_id] = 3

    get :show, params: {project_id: "project-sla-tests-tma", id: 3}

    assert_response :forbidden
  end

  ### Access audit: the global SLA configuration is managed by administrators only ###

  test "should render new and context menu on SLAs as admin" do
    @request.session[:user_id] = 1
    get :new
    assert_response :success
    get :context_menu, params: { ids: [1] }
    assert_response :success
    assert_select "a[href=?]", "/sla/slas/1/edit"
  end

  test "should create, update, delete and bulk delete SLAs as admin" do
    @request.session[:user_id] = 1
    assert_difference "Sla.count", 1 do
      post :create, params: { sla: { name: "Created SLA" } }
    end
    assert_redirected_to slas_path
    patch :update, params: { id: 1, sla: { name: "Updated SLA" } }
    assert_redirected_to slas_path
    assert_equal "Updated SLA", Sla.find(1).name
    deletables = create_deletable_slas
    assert_difference "Sla.count", -1 do
      delete :destroy, params: { id: deletables.first.id }
    end
    assert_difference "Sla.count", -2 do
      delete :destroy, params: { ids: deletables.drop(1).map(&:id) }
    end
    assert_redirected_to slas_path
  end

  # Users 2 and 3 may view SLAs of their projects (manage_sla / view_sla), user 5 has no SLA permission.
  { "anonymous" => nil, "project SLA manager" => 2, "Resolver with view_sla" => 3, "reporter without SLA permission" => 5 }.each do |label, user_id|
    test "should deny new and context menu on SLAs to #{label}" do
      @request.session[:user_id] = user_id
      get :new
      assert_access_denied(user_id)
      get :context_menu, params: { ids: [1] }
      assert_access_denied(user_id)
    end

    test "should deny SLA writes to #{label} without changing data" do
      deletables = create_deletable_slas
      assert_denied_without_change(user_id, Sla.find(1)) do
        post :create, params: { sla: { name: "Denied SLA" } }
        assert_access_denied(user_id)
        patch :update, params: { id: 1, sla: { name: "Denied SLA change" } }
        assert_access_denied(user_id)
        delete :destroy, params: { id: deletables.first.id }
        assert_access_denied(user_id)
        delete :destroy, params: { ids: deletables.map(&:id) }
        assert_access_denied(user_id)
      end
      assert_equal deletables.size, Sla.where(id: deletables.map(&:id)).count
    end
  end

  # Fresh SLAs without levels or project links, so a leaked destroy would really delete them.
  def create_deletable_slas
    Array.new(3) { |index| Sla.create!(name: "Deletable SLA #{index}") }
  end

end
