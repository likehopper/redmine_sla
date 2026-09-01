# frozen_string_literal: true

# File: redmine_sla/test/functional/sla_cache_controller_test.rb
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

class SlaCachesControllerTest < ApplicationSlaFunctionalsTestCase

  def setup
    super
    User.current = nil
    set_language_if_valid 'en'
    # puts "\n>>> Verification SQL : #{ActiveRecord::Base.connection.execute("SELECT count(*) FROM sla_caches").first}"
    # # Check if the table is empty OR if this is the first run
    # if !defined?(@@sla_update_done) || !@@sla_update_done || SlaCache.count == 0
    #   RedmineSlaTestBootstrap.ensure_update_sla!
    #   @@sla_update_done = true
    # end
    # puts "\n>>> Verification SQL : #{ActiveRecord::Base.connection.execute("SELECT count(*) FROM sla_caches").first}"
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

  test "should redirect on patch purge as anonymous" do
    with_settings :default_language => "en" do
      patch :purge
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}
    end
  end  

  test "should redirect on patch refresh as anonymous" do
    with_settings :default_language => "en" do
      patch :refresh
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

  test "should sanitize label_sla_notice and strip unsafe HTML as admin" do
    @request.session[:user_id] = 1
    original = I18n.backend.send(:translations).dig(:en, :label_sla_notice)
    begin
      I18n.backend.store_translations(:en, label_sla_notice: 'Cache <a href="%{url}">link</a><script>alert(1)</script>')
      with_settings :default_language => "en" do
        get :index
        assert_response :success
        assert_select 'div.title-sla_cache p' do
          assert_select 'script', false
          assert_select 'a[href]', text: 'link'
        end
      end
    ensure
      I18n.backend.store_translations(:en, label_sla_notice: original)
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

  test "should redirect on patch purge as admin" do
    sla_cache = SlaCache.first
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      patch :purge, params: { sla_cache: { id: sla_cache.id } }
      assert_response :redirect 
      assert_redirected_to sla_caches_path
    end
  end  
  
  test "should redirect on patch refresh as admin" do
    sla_cache = SlaCache.first
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      patch :refresh, params: { id: sla_cache.id }
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

  test "should forbidden on patch purge as manager" do
    sla_cache = SlaCache.first
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      patch :purge, params: { id: sla_cache.id }
      assert_response :forbidden      
    end
  end  
  
  test "should redirect on patch refresh as manager" do
    sla_cache = SlaCache.first
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      patch :refresh, params: { id: sla_cache.id }
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

  test "should forbidden on patch purge as developper" do
    sla_cache = SlaCache.where(project: 1).order(:id).first # project-sla-tests-tma
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      patch :purge, params: { id: sla_cache.id }
      assert_response :forbidden      
    end
  end  
  
  test "should forbidden on patch refresh as developper" do
    sla_cache = SlaCache.where(project: 1).order(:id).first # project-sla-tests-tma
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      patch :refresh, params: { id: sla_cache.id }
      assert_response :forbidden
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

  test "should forbidden on patch purge as sysadmin" do
    sla_cache = SlaCache.where(project: 2).order(:id).first # project-sla-tests-std
    @request.session[:user_id] = 4
    with_settings :default_language => "en" do
      patch :purge, params: { id: sla_cache.id }
      assert_response :forbidden      
    end
  end  
  
  test "should redirect on patch refresh as sysadmin" do
    sla_cache = SlaCache.where(project: 2).order(:id).first # project-sla-tests-std
    @request.session[:user_id] = 4
    with_settings :default_language => "en" do
      patch :refresh, params: { id: sla_cache.id }
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

  test "should forbidden on patch purge as reporter" do
    sla_cache = SlaCache.first
    @request.session[:user_id] = 5
    with_settings :default_language => "en" do
      patch :purge, params: { id: sla_cache.id }
      assert_response :forbidden      
    end
  end  
  
  test "should forbidden on patch refresh as reporter" do
    sla_cache = SlaCache.first
    @request.session[:user_id] = 5
    with_settings :default_language => "en" do
      patch :refresh, params: { id: sla_cache.id }
      assert_response :forbidden     
    end
  end

  ### context_menu ###
  # Tests for the context_menu action.
  # Key fix: can_show was previously User.current.admin? — only admin saw the
  # "show" link. It now uses visible? (same as can_refresh), so any user with
  # :view_sla on the issue's project sees the link.

  test "should redirect on get context_menu as anonymous" do
    sla_cache = SlaCache.first
    with_settings :default_language => "en" do
      get :context_menu, params: { ids: [sla_cache.id] }
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}
    end
  end

  test "should success on get context_menu as admin and show the show-link" do
    sla_cache = SlaCache.first
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      get :context_menu, params: { ids: [sla_cache.id] }
      assert_response :success
      assert_select 'a.icon-magnifier'
    end
  end

  # Before the fix, can_show = User.current.admin? → false for manager → no show link.
  # After the fix, can_show = visible? → true for manager with :view_sla → show link present.
  test "should success on get context_menu as manager and show the show-link" do
    sla_cache = SlaCache.first
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      get :context_menu, params: { ids: [sla_cache.id] }
      assert_response :success
      assert_select 'a.icon-magnifier'
    end
  end

  test "should success on get context_menu as developer on project 1 and show the show-link" do
    sla_cache = SlaCache.where(project: 1).order(:id).first
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      get :context_menu, params: { ids: [sla_cache.id] }
      assert_response :success
      assert_select 'a.icon-magnifier'
    end
  end

  test "should forbidden on get context_menu as reporter" do
    sla_cache = SlaCache.first
    @request.session[:user_id] = 5
    with_settings :default_language => "en" do
      get :context_menu, params: { ids: [sla_cache.id] }
      assert_response :forbidden
    end
  end

  test "should forbidden on get context_menu as other" do
    sla_cache = SlaCache.first
    @request.session[:user_id] = 6
    with_settings :default_language => "en" do
      get :context_menu, params: { ids: [sla_cache.id] }
      assert_response :forbidden
    end
  end


  ### explain ###
  # Tests for the explain action. Unlike show/refresh/context_menu (gated on
  # visible?, i.e. :view_sla), explain is gated on :manage_sla scoped to the
  # issue's own project (find_issue_for_explain's explicit
  # User.current.allowed_to?(:manage_sla, @project) check) -- so a user with
  # only :view_sla (developer on project 1, sysadmin on project 2) must be
  # forbidden here even though they can see the SLA block itself.

  test "should redirect on get explain as anonymous" do
    issue_id = SlaCache.first.issue_id
    with_settings :default_language => "en" do
      get :explain, params: { id: issue_id }
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}
    end
  end

  test "should success on get explain as admin" do
    issue_id = SlaCache.first.issue_id
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      get :explain, params: { id: issue_id }
      assert_response :success
    end
  end

  test "should success on get explain as manager on project 1" do
    issue_id = SlaCache.where(project: 1).order(:id).first.issue_id
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      get :explain, params: { id: issue_id }
      assert_response :success
    end
  end

  test "should success on get explain as manager on project 2" do
    issue_id = SlaCache.where(project: 2).order(:id).first.issue_id
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      get :explain, params: { id: issue_id }
      assert_response :success
    end
  end

  test "should forbidden on get explain as developper (view_sla only, no manage_sla)" do
    issue_id = SlaCache.where(project: 1).order(:id).first.issue_id
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      get :explain, params: { id: issue_id }
      assert_response :forbidden
    end
  end

  test "should forbidden on get explain as sysadmin (view_sla only, no manage_sla)" do
    issue_id = SlaCache.where(project: 2).order(:id).first.issue_id
    @request.session[:user_id] = 4
    with_settings :default_language => "en" do
      get :explain, params: { id: issue_id }
      assert_response :forbidden
    end
  end

  test "should forbidden on get explain as reporter" do
    issue_id = SlaCache.first.issue_id
    @request.session[:user_id] = 5
    with_settings :default_language => "en" do
      get :explain, params: { id: issue_id }
      assert_response :forbidden
    end
  end

  test "should forbidden on get explain as other" do
    issue_id = SlaCache.first.issue_id
    @request.session[:user_id] = 6
    with_settings :default_language => "en" do
      get :explain, params: { id: issue_id }
      assert_response :forbidden
    end
  end

  test "should success on get explain as admin for an issue with no matching SLA level" do
    issue = Issue.where(project_id: 1, tracker_id: 2).first # tracker with no sla_project_trackers association
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      get :explain, params: { id: issue.id }
      assert_response :success
      assert_select 'p.nodata'
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
  
  test "should forbidden on patch purge as other" do
    sla_cache = SlaCache.first
    @request.session[:user_id] = 6
    with_settings :default_language => "en" do
      patch :purge, params: { id: sla_cache.id }
      assert_response :forbidden      
    end
  end  
  
  test "should forbidden on patch refresh as other" do
    sla_cache = SlaCache.first
    @request.session[:user_id] = 6
    with_settings :default_language => "en" do
      patch :refresh, params: { id: sla_cache.id }
      assert_response :forbidden
    end
  end

end
