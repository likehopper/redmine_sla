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

class SlaCachesControllerTest < Redmine::ControllerTest

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

  test "should NoRoute on get new as anonymous" do
    assert_raises ActionController::UrlGenerationError do
      get :new
    end
  end  

  test "should redirect on post create as anonymous" do
    assert_raises ActionController::UrlGenerationError do
      post :create, :params => { sla_cache: { } }
    end
  end

  test "should redirect on get show as anonymous" do
    sla_cache = SlaCache.first
    with_settings :default_language => "en" do
      get :show, :params => { id: sla_cache.id }
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}
    end
  end

  test "should NoRoute on get edit as anonymous" do
    sla_cache = SlaCache.first
    assert_raises ActionController::UrlGenerationError do
      get :edit, :params => { id: sla_cache.id }
    end
  end

  test "should NoRoute on patch update as anonymous" do
    sla_cache = SlaCache.first
    assert_raises ActionController::UrlGenerationError do
      put :update, params: { id: sla_cache.id }
    end
    assert_raises ActionController::UrlGenerationError do
      patch :update, params: { id: sla_cache.id } 
    end
  end 

  test "should redirect on delete destroy as anonymous" do
    sla_cache = SlaCache.first
    with_settings :default_language => "en" do
      delete :destroy, :params => { id: sla_cache.id }
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}
    end
  end  

  test "should redirect on get purge as anonymous" do
    with_settings :default_language => "en" do
      get :purge
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}
    end
  end  

  test "should redirect on get refresh as anonymous" do
    with_settings :default_language => "en" do
      get :refresh
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
    end
  end

  test "should success on get new as admin" do
    @request.session[:user_id] = 1
    assert_raises ActionController::UrlGenerationError do
      get :new
    end
  end  

  test "should success on post create as admin" do
    @request.session[:user_id] = 1
    assert_raises ActionController::UrlGenerationError do
      post :create, :params => { sla_cache: { } }
    end
  end

  test "should success on get show as admin" do
    sla_cache = SlaCache.first
    @request.session[:user_id] = 1
    assert_raises ActionController::UrlGenerationError do
      get :edit, :params => { id: sla_cache.id }
    end
  end

  test "should success on get edit as admin" do
    sla_cache = SlaCache.first
    @request.session[:user_id] = 1
    assert_raises ActionController::UrlGenerationError do
      get :edit, :params => { id: sla_cache.id }
    end
  end

  test "should success on patch update as admin" do
    sla_cache = SlaCache.first
    @request.session[:user_id] = 1
    assert_raises ActionController::UrlGenerationError do
      put :update, params: { id: sla_cache.id }
    end
    assert_raises ActionController::UrlGenerationError do
      patch :update, params: { id: sla_cache.id } 
    end
  end  

  test "should redirect on delete destroy as admin" do
    sla_cache = SlaCache.first
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      delete :destroy, :params => { id: sla_cache.id }
      assert_response :redirect 
      assert_redirected_to sla_caches_path
    end
  end

  test "should redirect on get purge as admin" do
    sla_cache = SlaCache.first
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      get :purge, params: { sla_cache: { id: sla_cache.id } }
      assert_response :redirect 
      assert_redirected_to sla_caches_path
    end
  end  
  
  test "should redirect on get refresh as admin" do
    sla_cache = SlaCache.first
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      get :refresh, params: { id: sla_cache.id }
      assert_response :redirect 
      assert_redirected_to sla_caches_path    
    end
  end    

  ### As manager #2 ###

  test "should success on get index as manager" do
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      get :index
      assert_response 200
      assert_response :success
    end
  end

  test "should NoRoute on get new as manager" do
    @request.session[:user_id] = 2
    assert_raises ActionController::UrlGenerationError do
      get :new
    end
  end  

  test "should NoRoute on post create as manager" do
    @request.session[:user_id] = 2
    assert_raises ActionController::UrlGenerationError do
      post :create, :params => { sla_cache: { } }
    end
  end

  test "should redirect on get show as manager" do
    sla_cache = SlaCache.first
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      get :show, :params => { id: sla_cache.id }
      assert_response :redirect 
      assert_redirected_to sla_caches_path
    end
  end

  test "should NoRoute on get edit as manager" do
    sla_cache = SlaCache.first
    @request.session[:user_id] = 2
    assert_raises ActionController::UrlGenerationError do
      get :edit, :params => { id: sla_cache.id }
    end
  end
    
  test "should NoRoute on patch update as manager" do
    sla_cache = SlaCache.first
    @request.session[:user_id] = 2
    assert_raises ActionController::UrlGenerationError do
      put :update, params: { id: sla_cache.id }
    end
    assert_raises ActionController::UrlGenerationError do
      patch :update, params: { id: sla_cache.id } 
    end
  end
  
  test "should redirect on get destroy as manager" do
    sla_cache = SlaCache.first
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      delete :destroy, :params => { id: sla_cache.id }
      assert_response :redirect 
      assert_redirected_to sla_caches_path
    end
  end

  test "should forbidden on get purge as manager" do
    sla_cache = SlaCache.first
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      get :purge, params: { id: sla_cache.id }
      assert_response :forbidden      
    end
  end  
  
  test "should redirect on get refresh as manager" do
    sla_cache = SlaCache.first
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      get :refresh, params: { id: sla_cache.id } 
      assert_response :redirect 
      assert_redirected_to sla_caches_path      
    end
  end      

  ### As developper #3 ###

  test "should success on get index as developper" do
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      get :index
      assert_response 200
      assert_response :success
    end
  end

  test "should NoRoute on get new as developper" do
    @request.session[:user_id] = 3
    assert_raises ActionController::UrlGenerationError do
      get :new
    end
  end  

  test "should redirect on get show as developper" do
    sla_cache = SlaCache.where(project: 1).order(:id).first # project-sla-tests-tma
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      get :show, :params => { id: sla_cache.id }
      assert_response :redirect 
      assert_redirected_to sla_caches_path
    end
  end

  test "should NoRoute on post create as developper" do
    @request.session[:user_id] = 3
    assert_raises ActionController::UrlGenerationError do
      post :create, :params => { sla_cache: { } }
    end
  end  

  test "should NoRoute on get edit as developper" do
    sla_cache = SlaCache.where(project: 1).order(:id).first # project-sla-tests-tma
    @request.session[:user_id] = 3
    assert_raises ActionController::UrlGenerationError do
      get :edit, :params => { id: sla_cache.id }
    end
  end
 
  test "should NoRoute on patch update as developper" do
    sla_cache = SlaCache.where(project: 1).order(:id).first # project-sla-tests-tma
    @request.session[:user_id] = 3
    assert_raises ActionController::UrlGenerationError do
      put :update, params: { id: sla_cache.id }
    end
    assert_raises ActionController::UrlGenerationError do
      patch :update, params: { id: sla_cache.id } 
    end
  end

  test "should forbidden on get delete destroy as developper" do
    sla_cache = SlaCache.where(project: 1).order(:id).first # project-sla-tests-tma
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      delete :destroy, :params => { id: sla_cache.id }
      assert_response :forbidden
    end
  end

  test "should forbidden on get purge as developper" do
    sla_cache = SlaCache.where(project: 1).order(:id).first # project-sla-tests-tma
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      get :purge, params: { id: sla_cache.id }
      assert_response :forbidden      
    end
  end  
  
  test "should forbidden on get refresh as developper" do
    sla_cache = SlaCache.where(project: 1).order(:id).first # project-sla-tests-tma
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      get :refresh, params: { id: sla_cache.id } 
      assert_response :redirect 
      assert_redirected_to sla_caches_path    
    end
  end        

  ### As sysadmin #4 ###

  test "should success on get index as sysadmin" do
    @request.session[:user_id] = 4
    with_settings :default_language => "en" do
      get :index
      assert_response 200
      assert_response :success
    end
  end

  test "should NoRoute on get new as sysadmin" do
    @request.session[:user_id] = 4
    assert_raises ActionController::UrlGenerationError do
      get :new
    end
  end

  test "should forbidden on get show as sysadmin" do
    sla_cache = SlaCache.where(project: 2).order(:id).first # project-sla-tests-std
    @request.session[:user_id] = 4
    with_settings :default_language => "en" do
      get :show, :params => { id: sla_cache.id }
      assert_response :redirect 
      assert_redirected_to sla_caches_path 
    end
  end

  test "should NoRoute on get edit as sysadmin" do
    sla_cache = SlaCache.where(project: 2).order(:id).first # project-sla-tests-std
    @request.session[:user_id] = 4
    assert_raises ActionController::UrlGenerationError do
      get :edit, :params => { id: sla_cache.id }
    end
  end

  test "should NoRoute on patch update as sysadmin" do
    sla_cache = SlaCache.where(project: 2).order(:id).first # project-sla-tests-std
    @request.session[:user_id] = 4
    assert_raises ActionController::UrlGenerationError do
      put :update, params: { id: sla_cache.id }
    end
    assert_raises ActionController::UrlGenerationError do
      patch :update, params: { id: sla_cache.id } 
    end
  end

  test "should forbidden on get delete destroy as sysadmin" do
    sla_cache = SlaCache.where(project: 2).order(:id).first # project-sla-tests-std
    @request.session[:user_id] = 4
    with_settings :default_language => "en" do
      delete :destroy, :params => { id: sla_cache.id }
      assert_response :forbidden
    end
  end  

  test "should forbidden on get purge as sysadmin" do
    sla_cache = SlaCache.where(project: 2).order(:id).first # project-sla-tests-std
    @request.session[:user_id] = 4
    with_settings :default_language => "en" do
      get :purge, params: { id: sla_cache.id }
      assert_response :forbidden      
    end
  end  
  
  test "should redirect on get refresh as sysadmin" do
    sla_cache = SlaCache.where(project: 2).order(:id).first # project-sla-tests-std
    @request.session[:user_id] = 4
    with_settings :default_language => "en" do
      get :refresh, params: { id: sla_cache.id } 
      assert_response :redirect 
      assert_redirected_to sla_caches_path   
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

  test "should NoRoute on get new as reporter" do
    @request.session[:user_id] = 5
    assert_raises ActionController::UrlGenerationError do
      get :new
    end
  end  

  test "should forbidden on get show as reporter" do
    sla_cache = SlaCache.first
    @request.session[:user_id] = 5
    with_settings :default_language => "en" do
      get :show, :params => { id: sla_cache.id }
      assert_response :forbidden
    end
  end

  test "should NoRoute on get edit as reporter" do
    sla_cache = SlaCache.first
    @request.session[:user_id] = 5
    assert_raises ActionController::UrlGenerationError do
      get :edit, :params => { id: sla_cache.id }
    end
  end

  test "should NoRoute on patch update as reporter" do
    sla_cache = SlaCache.first
    @request.session[:user_id] = 5
    assert_raises ActionController::UrlGenerationError do
      put :update, params: { id: sla_cache.id }
    end
    assert_raises ActionController::UrlGenerationError do
      patch :update, params: { id: sla_cache.id } 
    end
  end  

  test "should forbidden on get delete destroy as reporter" do
    sla_cache = SlaCache.first
    @request.session[:user_id] = 5
    with_settings :default_language => "en" do
      delete :destroy, :params => { id: sla_cache.id }
      assert_response :forbidden
    end
  end

  test "should forbidden on get purge as reporter" do
    sla_cache = SlaCache.first
    @request.session[:user_id] = 5
    with_settings :default_language => "en" do
      get :purge, params: { id: sla_cache.id }
      assert_response :forbidden      
    end
  end  
  
  test "should forbidden on get refresh as reporter" do
    sla_cache = SlaCache.first
    @request.session[:user_id] = 5
    with_settings :default_language => "en" do
      get :refresh, params: { id: sla_cache.id } 
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

  test "should NoRoute on get new as other" do
    @request.session[:user_id] = 6
    assert_raises ActionController::UrlGenerationError do
      get :new
    end
  end

  test "should forbidden on get show as other" do
    sla_cache = SlaCache.first
    @request.session[:user_id] = 6
    with_settings :default_language => "en" do
      get :show, :params => { id: sla_cache.id }
      assert_response :forbidden
    end
  end

  test "should NoRoute on get edit as other" do
    sla_cache = SlaCache.first
    @request.session[:user_id] = 6
    assert_raises ActionController::UrlGenerationError do
      get :edit, :params => { id: sla_cache.id }
    end
  end

  test "should NoRoute on patch update as other" do
    sla_cache = SlaCache.first
    @request.session[:user_id] = 6
    assert_raises ActionController::UrlGenerationError do
      put :update, params: { id: sla_cache.id }
    end
    assert_raises ActionController::UrlGenerationError do
      patch :update, params: { id: sla_cache.id }
    end
  end  

  test "should forbidden on get delete destroy as other" do
    sla_cache = SlaCache.first
    @request.session[:user_id] = 6
    with_settings :default_language => "en" do
      delete :destroy, :params => { id: sla_cache.id }
      assert_response :forbidden
    end
  end
  
  test "should forbidden on get purge as other" do
    sla_cache = SlaCache.first
    @request.session[:user_id] = 6
    with_settings :default_language => "en" do
      get :purge, params: { id: sla_cache.id }
      assert_response :forbidden      
    end
  end  
  
  test "should forbidden on get refresh as other" do
    sla_cache = SlaCache.first
    @request.session[:user_id] = 6
    with_settings :default_language => "en" do
      get :refresh, params: { id: sla_cache.id } 
      assert_response :forbidden
    end
  end

end

