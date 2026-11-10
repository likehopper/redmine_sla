# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

# File: redmine_sla/test/functional/sla_cache_controller_test.rb
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

  # Cache rows are not fixtures: update_sla recalculates them, so their ids
  # depend on the database sequence and must be looked up.
  def project_cache(project_id)
    SlaCache.where(project_id: project_id).order(:id).first!
  end

  def cache_counts_by_project
    SlaCache.group(:project_id).count
  end

  # "other" has no membership in the fixtures: it becomes a manager of
  # project 1 only, so project 2 stays out of its reach.
  def log_in_as_manager_of_project_one_only
    user = User.find_by!(login: "other")
    Member.create!(project: Project.find(1), principal: user, role_ids: [Role.find_by!(name: "Manager").id])
    @request.session[:user_id] = user.id
  end

  # Requests every project-scoped action on a project 1 cache and expects the
  # same denial for each one, without any cache being removed.
  def assert_project_cache_actions_denied(expected_response)
    cache = project_cache(1)
    counts_before = cache_counts_by_project
    assert_operator counts_before[1], :>, 0

    with_settings :default_language => "en" do
      [
        -> { get :index, params: { project_id: "project-sla-tests-tma" } },
        -> { get :show, params: { project_id: "project-sla-tests-tma", id: cache.id } },
        -> { get :context_menu, params: { project_id: "project-sla-tests-tma", ids: [cache.id] } },
        -> { patch :refresh, params: { project_id: "project-sla-tests-tma", id: cache.id } },
        -> { delete :destroy, params: { project_id: "project-sla-tests-tma", id: cache.id } },
        -> { patch :purge, params: { project_id: "project-sla-tests-tma" } }
      ].each do |request_action|
        request_action.call
        assert_response expected_response
        # A successful refresh, destroy or purge also redirects.
        assert_redirected_to %r{#{signin_path}} if expected_response == :redirect
      end
    end

    assert SlaCache.exists?(cache.id)
    assert_equal counts_before, cache_counts_by_project
  end

  ### As anonymous ###

  test "should redirect on get index as anonymous" do
    with_settings :default_language => "en" do
      get :index
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}
    end
  end

  test "should redirect project index as anonymous" do
    with_settings :default_language => "en" do
      get :index, params: { project_id: "project-sla-tests-tma" }
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}
    end
  end

  test "Resolver should only read caches from its projects" do
    resolver = User.find(3)
    assert_equal "Resolver", resolver.roles_for_project(Project.find(1)).first.name
    @request.session[:user_id] = resolver.id

    get :index, params: { project_id: "project-sla-tests-tma", "issue.status_id" => "*" }
    assert_response :success
    entities = @controller.instance_variable_get(:@entities)
    assert_not_empty entities
    assert entities.all? { |cache| cache.project_id == 1 }

    get :index, params: { project_id: "project-sla-tests-std" }
    assert_response :forbidden

    get :index, params: { "issue.status_id" => "*" }
    assert_response :success
    entities = @controller.instance_variable_get(:@entities)
    assert_not_empty entities
    assert entities.all? { |cache| [1, 4].include?(cache.project_id) }
  end

  test "Resolver cannot read a cache through another project context" do
    @request.session[:user_id] = 3
    foreign_cache = SlaCache.where(project_id: 2).first

    get :show, params: { project_id: "project-sla-tests-tma", id: foreign_cache.id }
    assert_response :forbidden
  end

  # Reading caches requires :view_sla; :manage_sla alone does not imply it.
  test "manage_sla without view_sla cannot read the project cache list" do
    user = User.find_by!(login: "other")
    role = Role.create!(name: "SLA manage only", permissions: [:view_project, :manage_sla])
    Member.create!(project: Project.find(1), principal: user, role_ids: [role.id])
    @request.session[:user_id] = user.id

    get :index, params: { project_id: "project-sla-tests-tma" }
    assert_response :forbidden
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
    sla_cache = project_cache(1)
    with_settings :default_language => "en" do
      get :show, :params => { id: sla_cache.id }
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}
    end
  end

  test "should NoRoute on get edit as anonymous" do
    sla_cache = project_cache(1)
    assert_raises ActionController::UrlGenerationError do
      get :edit, :params => { id: sla_cache.id }
    end
  end

  test "should NoRoute on patch update as anonymous" do
    sla_cache = project_cache(1)
    assert_raises ActionController::UrlGenerationError do
      put :update, params: { id: sla_cache.id }
    end
    assert_raises ActionController::UrlGenerationError do
      patch :update, params: { id: sla_cache.id } 
    end
  end 

  test "should redirect on delete destroy as anonymous" do
    sla_cache = project_cache(1)
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
    sla_cache = project_cache(1)
    @request.session[:user_id] = 1
    assert_raises ActionController::UrlGenerationError do
      get :edit, :params => { id: sla_cache.id }
    end
  end

  test "should success on get edit as admin" do
    sla_cache = project_cache(1)
    @request.session[:user_id] = 1
    assert_raises ActionController::UrlGenerationError do
      get :edit, :params => { id: sla_cache.id }
    end
  end

  test "should success on patch update as admin" do
    sla_cache = project_cache(1)
    @request.session[:user_id] = 1
    assert_raises ActionController::UrlGenerationError do
      put :update, params: { id: sla_cache.id }
    end
    assert_raises ActionController::UrlGenerationError do
      patch :update, params: { id: sla_cache.id } 
    end
  end  

  test "should redirect on delete destroy as admin" do
    sla_cache = project_cache(1)
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      delete :destroy, :params => { id: sla_cache.id }
      assert_response :redirect 
      assert_redirected_to sla_caches_path
    end
  end

  test "should redirect on patch purge as admin" do
    sla_cache = project_cache(1)
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      patch :purge, params: { sla_cache: { id: sla_cache.id } }
      assert_response :redirect
      assert_redirected_to sla_caches_path
    end
    assert_equal 0, SlaCache.count
  end
  
  test "should redirect on patch refresh as admin" do
    sla_cache = project_cache(1)
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
    sla_cache = project_cache(1)
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      get :show, :params => { project_id: "project-sla-tests-tma", id: sla_cache.id }
      assert_response :redirect 
      assert_redirected_to sla_caches_path
    end
  end

  test "should NoRoute on get edit as manager" do
    sla_cache = project_cache(1)
    @request.session[:user_id] = 2
    assert_raises ActionController::UrlGenerationError do
      get :edit, :params => { id: sla_cache.id }
    end
  end
    
  test "should NoRoute on patch update as manager" do
    sla_cache = project_cache(1)
    @request.session[:user_id] = 2
    assert_raises ActionController::UrlGenerationError do
      put :update, params: { id: sla_cache.id }
    end
    assert_raises ActionController::UrlGenerationError do
      patch :update, params: { id: sla_cache.id } 
    end
  end
  
  test "should redirect on get destroy as manager" do
    sla_cache = project_cache(1)
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      delete :destroy, :params => { project_id: "project-sla-tests-tma", id: sla_cache.id }
      assert_response :redirect 
      assert_redirected_to project_sla_caches_path(Project.find(1))
    end
  end

  # A manager of every project is still not allowed to purge all at once.
  test "should forbidden on patch purge as manager" do
    sla_cache = project_cache(1)
    counts_before = cache_counts_by_project
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      patch :purge, params: { id: sla_cache.id }
      assert_response :forbidden
    end
    assert_equal counts_before, cache_counts_by_project
  end
  
  test "should redirect on patch refresh as manager" do
    sla_cache = project_cache(1)
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      patch :refresh, params: { project_id: "project-sla-tests-tma", id: sla_cache.id }
      assert_response :redirect 
      assert_redirected_to project_sla_caches_path(Project.find(1))
    end
  end      

  ### As developper #3 ###

  test "should success on get index as developper" do
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      get :index
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
      get :show, :params => { project_id: "project-sla-tests-tma", id: sla_cache.id }
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
      get :show, :params => { project_id: "project-sla-tests-std", id: sla_cache.id }
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
    sla_cache = project_cache(1)
    @request.session[:user_id] = 5
    with_settings :default_language => "en" do
      get :show, :params => { id: sla_cache.id }
      assert_response :forbidden
    end
  end

  test "should NoRoute on get edit as reporter" do
    sla_cache = project_cache(1)
    @request.session[:user_id] = 5
    assert_raises ActionController::UrlGenerationError do
      get :edit, :params => { id: sla_cache.id }
    end
  end

  test "should NoRoute on patch update as reporter" do
    sla_cache = project_cache(1)
    @request.session[:user_id] = 5
    assert_raises ActionController::UrlGenerationError do
      put :update, params: { id: sla_cache.id }
    end
    assert_raises ActionController::UrlGenerationError do
      patch :update, params: { id: sla_cache.id } 
    end
  end  

  test "should forbidden on get delete destroy as reporter" do
    sla_cache = project_cache(1)
    @request.session[:user_id] = 5
    with_settings :default_language => "en" do
      delete :destroy, :params => { id: sla_cache.id }
      assert_response :forbidden
    end
  end

  test "should forbidden on patch purge as reporter" do
    sla_cache = project_cache(1)
    @request.session[:user_id] = 5
    with_settings :default_language => "en" do
      patch :purge, params: { id: sla_cache.id }
      assert_response :forbidden      
    end
  end  
  
  test "should forbidden on patch refresh as reporter" do
    sla_cache = project_cache(1)
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
    sla_cache = project_cache(1)
    with_settings :default_language => "en" do
      get :context_menu, params: { project_id: "project-sla-tests-tma", ids: [sla_cache.id] }
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}
    end
  end

  test "should success on get context_menu as admin and show the show-link" do
    sla_cache = project_cache(1)
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      get :context_menu, params: { project_id: "project-sla-tests-tma", ids: [sla_cache.id] }
      assert_response :success
      assert_select 'a.icon-magnifier'
    end
  end

  # Before the fix, can_show = User.current.admin? → false for manager → no show link.
  # After the fix, can_show = visible? → true for manager with :view_sla → show link present.
  test "should success on get context_menu as manager and show the show-link" do
    sla_cache = project_cache(1)
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      get :context_menu, params: { project_id: "project-sla-tests-tma", ids: [sla_cache.id] }
      assert_response :success
      assert_select 'a.icon-magnifier'
    end
  end

  test "should success on get context_menu as developer on project 1 and show the show-link" do
    sla_cache = SlaCache.where(project: 1).order(:id).first
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      get :context_menu, params: { project_id: "project-sla-tests-tma", ids: [sla_cache.id] }
      assert_response :success
      assert_select 'a.icon-magnifier'
    end
  end

  test "should forbidden on get context_menu as reporter" do
    sla_cache = project_cache(1)
    @request.session[:user_id] = 5
    with_settings :default_language => "en" do
      get :context_menu, params: { ids: [sla_cache.id] }
      assert_response :forbidden
    end
  end

  test "should forbidden on get context_menu as other" do
    sla_cache = project_cache(1)
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
    issue_id = project_cache(1).issue_id
    with_settings :default_language => "en" do
      get :explain, params: { id: issue_id }
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}
    end
  end

  test "should success on get explain as admin" do
    issue_id = project_cache(1).issue_id
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
    issue_id = project_cache(1).issue_id
    @request.session[:user_id] = 5
    with_settings :default_language => "en" do
      get :explain, params: { id: issue_id }
      assert_response :forbidden
    end
  end

  test "should forbidden on get explain as other" do
    issue_id = project_cache(1).issue_id
    @request.session[:user_id] = 6
    with_settings :default_language => "en" do
      get :explain, params: { id: issue_id }
      assert_response :forbidden
    end
  end

  test "should forbidden on get explain as admin when the SLA module is disabled" do
    issue_id = SlaCache.where(project: 1).order(:id).first.issue_id
    Project.find(1).disable_module!(:sla)
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      get :explain, params: { id: issue_id }
      assert_response :forbidden
    end
  end

  test "should forbidden on get explain as manager when the SLA module is disabled" do
    issue_id = SlaCache.where(project: 1).order(:id).first.issue_id
    Project.find(1).disable_module!(:sla)
    @request.session[:user_id] = 2
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
    sla_cache = project_cache(1)
    @request.session[:user_id] = 6
    with_settings :default_language => "en" do
      get :show, :params => { id: sla_cache.id }
      assert_response :forbidden
    end
  end

  test "should NoRoute on get edit as other" do
    sla_cache = project_cache(1)
    @request.session[:user_id] = 6
    assert_raises ActionController::UrlGenerationError do
      get :edit, :params => { id: sla_cache.id }
    end
  end

  test "should NoRoute on patch update as other" do
    sla_cache = project_cache(1)
    @request.session[:user_id] = 6
    assert_raises ActionController::UrlGenerationError do
      put :update, params: { id: sla_cache.id }
    end
    assert_raises ActionController::UrlGenerationError do
      patch :update, params: { id: sla_cache.id }
    end
  end  

  test "should forbidden on get delete destroy as other" do
    sla_cache = project_cache(1)
    @request.session[:user_id] = 6
    with_settings :default_language => "en" do
      delete :destroy, :params => { id: sla_cache.id }
      assert_response :forbidden
    end
  end
  
  test "should forbidden on patch purge as other" do
    sla_cache = project_cache(1)
    @request.session[:user_id] = 6
    with_settings :default_language => "en" do
      patch :purge, params: { id: sla_cache.id }
      assert_response :forbidden      
    end
  end  
  
  test "should forbidden on patch refresh as other" do
    sla_cache = project_cache(1)
    @request.session[:user_id] = 6
    with_settings :default_language => "en" do
      patch :refresh, params: { id: sla_cache.id }
      assert_response :forbidden
    end
  end

  ### Project-scoped permission boundaries ###

  test "anonymous is sent to login for every project-scoped cache action" do
    assert_project_cache_actions_denied(:redirect)
  end

  test "non-member is forbidden every project-scoped cache action" do
    @request.session[:user_id] = 6
    assert_project_cache_actions_denied(:forbidden)
  end

  test "member whose role lacks view_sla is forbidden every project-scoped cache action" do
    @request.session[:user_id] = 5
    assert_equal ["Reporter"], User.find(5).roles_for_project(Project.find(1)).map(&:name)
    assert_project_cache_actions_denied(:forbidden)
  end

  test "view_sla without manage_sla cannot refresh, destroy or purge caches of its project" do
    cache = project_cache(1)
    counts_before = cache_counts_by_project
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      get :index, params: { project_id: "project-sla-tests-tma" }
      assert_response :success
      patch :refresh, params: { project_id: "project-sla-tests-tma", id: cache.id }
      assert_response :forbidden
      delete :destroy, params: { project_id: "project-sla-tests-tma", id: cache.id }
      assert_response :forbidden
      patch :purge, params: { project_id: "project-sla-tests-tma" }
      assert_response :forbidden
    end
    assert_equal counts_before, cache_counts_by_project
  end

  test "project manager purge removes only the caches of that project" do
    counts_before = cache_counts_by_project
    other_projects_before = counts_before.except(1)
    assert_operator counts_before[1], :>, 0
    assert_operator other_projects_before.values.sum, :>, 0
    spents_of_other_projects = SlaCacheSpent.where.not(project_id: 1).count
    assert_operator spents_of_other_projects, :>, 0

    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      patch :purge, params: { project_id: "project-sla-tests-tma" }
      assert_response :redirect
      assert_redirected_to project_sla_caches_path(Project.find(1))
    end

    assert_equal 0, SlaCache.where(project_id: 1).count
    assert_equal other_projects_before, cache_counts_by_project
    assert_equal spents_of_other_projects, SlaCacheSpent.where.not(project_id: 1).count
  end

  test "project manager destroys a cache of its own project" do
    cache = project_cache(1)
    log_in_as_manager_of_project_one_only
    with_settings :default_language => "en" do
      delete :destroy, params: { project_id: "project-sla-tests-tma", id: cache.id }
      assert_response :redirect
      assert_redirected_to project_sla_caches_path(Project.find(1))
    end
    assert_not SlaCache.exists?(cache.id)
  end

  test "project manager refreshes a cache of its own project" do
    cache = project_cache(1)
    log_in_as_manager_of_project_one_only
    with_settings :default_language => "en" do
      patch :refresh, params: { project_id: "project-sla-tests-tma", id: cache.id }
      assert_response :redirect
      assert_redirected_to project_sla_caches_path(Project.find(1))
    end
    assert SlaCache.exists?(issue_id: cache.issue_id, project_id: 1)
  end

  test "project manager cannot read or change caches of a project it does not manage" do
    foreign_cache = project_cache(2)
    own_cache = project_cache(1)
    counts_before = cache_counts_by_project
    log_in_as_manager_of_project_one_only
    with_settings :default_language => "en" do
      get :index, params: { project_id: "project-sla-tests-std" }
      assert_response :forbidden
      get :show, params: { id: foreign_cache.id }
      assert_response :forbidden
      get :context_menu, params: { ids: [foreign_cache.id] }
      assert_response :forbidden
      patch :refresh, params: { id: foreign_cache.id }
      assert_response :forbidden
      patch :refresh, params: { project_id: "project-sla-tests-std", id: foreign_cache.id }
      assert_response :forbidden
      delete :destroy, params: { id: foreign_cache.id }
      assert_response :forbidden
      patch :purge, params: { project_id: "project-sla-tests-std" }
      assert_response :forbidden
      patch :purge
      assert_response :forbidden
    end
    assert_equal counts_before, cache_counts_by_project
    assert SlaCache.exists?(own_cache.id)
  end

  # The project in the URL is authorized, the row id must not escape it.
  test "project manager cannot reach a foreign cache through its own project context" do
    foreign_cache = project_cache(2)
    log_in_as_manager_of_project_one_only
    with_settings :default_language => "en" do
      get :show, params: { project_id: "project-sla-tests-tma", id: foreign_cache.id }
      assert_response :forbidden
      get :context_menu, params: { project_id: "project-sla-tests-tma", ids: [foreign_cache.id] }
      assert_response :forbidden
      patch :refresh, params: { project_id: "project-sla-tests-tma", id: foreign_cache.id }
      assert_response :forbidden
      delete :destroy, params: { project_id: "project-sla-tests-tma", id: foreign_cache.id }
      assert_response :forbidden
    end
    assert SlaCache.exists?(foreign_cache.id)
  end

  # manage_sla on project 1 passes the global authorization, and view_sla on
  # project 2 makes the foreign cache visible: only the per-project
  # management check stands between them.
  test "manager of one project cannot refresh or destroy a cache it only views in another project" do
    foreign_cache = project_cache(2)
    own_cache = project_cache(1)
    log_in_as_manager_of_project_one_only
    user = User.find_by!(login: "other")
    Member.create!(project: Project.find(2), principal: user, role_ids: [Role.find_by!(name: "Resolver").id])
    # visible? checks the issue with User.current: check both parts for this user.
    assert user.allowed_to?(:view_sla, Project.find(2))
    assert foreign_cache.issue.visible?(user)
    assert_not user.allowed_to?(:manage_sla, Project.find(2))
    counts_before = cache_counts_by_project
    updated_on_before = foreign_cache.reload.updated_on

    with_settings :default_language => "en" do
      patch :refresh, params: { id: foreign_cache.id }
      assert_response :forbidden
      delete :destroy, params: { id: foreign_cache.id }
      assert_response :forbidden
      delete :destroy, params: { ids: [own_cache.id, foreign_cache.id] }
      assert_response :forbidden
    end
    assert_equal counts_before, cache_counts_by_project
    assert_equal updated_on_before, foreign_cache.reload.updated_on

    # The same request on the managed project goes through.
    with_settings :default_language => "en" do
      delete :destroy, params: { id: own_cache.id }
      assert_response :redirect
    end
    assert_not SlaCache.exists?(own_cache.id)
  end

  test "bulk destroy mixing an allowed and a foreign cache removes neither" do
    own_cache = project_cache(1)
    foreign_cache = project_cache(2)
    log_in_as_manager_of_project_one_only
    with_settings :default_language => "en" do
      delete :destroy, params: { ids: [own_cache.id, foreign_cache.id] }
      assert_response :forbidden
    end
    assert SlaCache.exists?(own_cache.id)
    assert SlaCache.exists?(foreign_cache.id)
  end

  ### SLA module disabled ###

  test "project-scoped cache list is forbidden once the SLA module is disabled" do
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      get :index, params: { project_id: "project-sla-tests-tma" }
      assert_response :success
      Project.find(1).disable_module!(:sla)
      get :index, params: { project_id: "project-sla-tests-tma" }
      assert_response :forbidden
    end
  end

  # Disabling the module through the UI purges the caches; removing the
  # module row directly keeps them, so access must depend on the module
  # itself and not only on the absence of rows.
  test "caches left on a project without the SLA module are denied even to admin and manager" do
    cache = project_cache(1)
    EnabledModule.where(project_id: 1, name: "sla").delete_all
    counts_before = cache_counts_by_project
    assert_operator counts_before[1], :>, 0

    [1, 2].each do |user_id|
      @request.session[:user_id] = user_id
      with_settings :default_language => "en" do
        get :index, params: { project_id: "project-sla-tests-tma" }
        assert_response :forbidden
        patch :purge, params: { project_id: "project-sla-tests-tma" }
        assert_response :forbidden
        get :show, params: { id: cache.id }
        assert_response :forbidden
        patch :refresh, params: { id: cache.id }
        assert_response :forbidden
        delete :destroy, params: { id: cache.id }
        assert_response :forbidden
      end
    end
    assert_equal counts_before, cache_counts_by_project
  end

  test "global cache list hides projects whose SLA module is disabled" do
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      get :index, params: { "issue.status_id" => "*", "per_page" => 100 }
      assert_response :success
      assert_equal @controller.instance_variable_get(:@entity_count), @controller.instance_variable_get(:@entities).size
      assert_includes @controller.instance_variable_get(:@entities).map(&:project_id), 1

      EnabledModule.where(project_id: 1, name: "sla").delete_all
      get :index, params: { "issue.status_id" => "*", "per_page" => 100 }
      assert_response :success
      project_ids = @controller.instance_variable_get(:@entities).map(&:project_id)
      assert_not_empty project_ids
      assert_not_includes project_ids, 1
    end
  end

end
