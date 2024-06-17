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

class SlasControllerTest < Redmine::ControllerTest

  include Redmine::I18n

  def setup
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
      post(:create, :params => { sla: { :name => "SLA test" } } )
      assert_response :forbidden
    end
  end

  test "should forbidden on get show as manager" do
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      get(:show, :params => {:id => 1})
      assert_response :forbidden
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

  test "should forbidden on get index as developper" do
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      get :index
      assert_response :forbidden
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

  test "should forbidden on get show as developper" do
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      get(:show, :params => {:id => 1})
      assert_response :forbidden
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

  test "should forbidden on get index as sysadmin" do
    @request.session[:user_id] = 4
    with_settings :default_language => "en" do
      get :index
      assert_response :forbidden
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

end