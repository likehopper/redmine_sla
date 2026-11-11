# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

# File: redmine_sla/test/functional/sla_cache_spent_controller_test.rb
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

class SlaCacheSpentsControllerTest < ApplicationSlaFunctionalsTestCase

  def setup
    super
    User.current = nil
    set_language_if_valid 'en'
  end

  # Spent rows are not fixtures: update_sla recalculates them, so their ids
  # depend on the database sequence and must be looked up.
  def project_spent(project_id)
    SlaCacheSpent.where(project_id: project_id).order(:id).first!
  end

  def spent_counts_by_project
    SlaCacheSpent.group(:project_id).count
  end

  # "other" has no membership in the fixtures: it becomes a manager of
  # project 1 only, so project 2 stays out of its reach.
  def log_in_as_manager_of_project_one_only
    user = User.find_by!(login: "other")
    Member.create!(project: Project.find(1), principal: user, role_ids: [Role.find_by!(name: "Manager").id])
    @request.session[:user_id] = user.id
  end

  # Authenticates REST calls with the user's key, as API clients do.
  def with_api_key_of(user_id)
    with_settings :rest_api_enabled => "1" do
      yield User.find(user_id).api_key
    end
  end

  # Spent lists have no project route: the project context is the
  # project_id query parameter, which find_optional_project honours.
  # Requests every action in project 1 context and expects the same denial
  # for each one, without any spent row being removed.
  def assert_project_spent_actions_denied(expected_response)
    spent = project_spent(1)
    counts_before = spent_counts_by_project
    assert_operator counts_before[1], :>, 0

    with_settings :default_language => "en" do
      [
        -> { get :index, params: { project_id: "project-sla-tests-tma" } },
        -> { get :show, params: { project_id: "project-sla-tests-tma", id: spent.id } },
        -> { get :context_menu, params: { project_id: "project-sla-tests-tma", ids: [spent.id] } },
        -> { patch :refresh, params: { project_id: "project-sla-tests-tma", id: spent.id } },
        -> { delete :destroy, params: { project_id: "project-sla-tests-tma", id: spent.id } },
        -> { patch :purge, params: { project_id: "project-sla-tests-tma" } }
      ].each do |request_action|
        request_action.call
        assert_response expected_response
        # A successful refresh, destroy or purge also redirects.
        assert_redirected_to %r{#{signin_path}} if expected_response == :redirect
      end
    end

    assert SlaCacheSpent.exists?(spent.id)
    assert_equal counts_before, spent_counts_by_project
  end

  ### As anonymous ###

  test "should redirect on get index as anonymous" do
    with_settings :default_language => "en" do
      get :index
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}
    end
  end

  test "Resolver should only read cache spents from its projects" do
    resolver = User.find(3)
    assert_equal "Resolver", resolver.roles_for_project(Project.find(1)).first.name
    @request.session[:user_id] = resolver.id

    get :index, params: { "issue.status_id" => "*" }
    assert_response :success
    entities = @controller.instance_variable_get(:@entities)
    assert_not_empty entities
    assert entities.all? { |spent| [1, 4].include?(spent.project_id) }
  end

  test "Resolver cannot read a cache spent from another project" do
    @request.session[:user_id] = 3
    foreign_spent = SlaCacheSpent.where(project_id: 2).first

    get :show, params: { id: foreign_spent.id }
    assert_response :forbidden
  end

  test "should NoRoute on get new as anonymous" do
    assert_raises ActionController::UrlGenerationError do
      get :new
    end
  end  

  test "should redirect on post create as anonymous" do
    assert_raises ActionController::UrlGenerationError do
      post :create, :params => { sla_cache_spent: { } }
    end
  end

  test "should redirect on get show as anonymous" do
    with_settings :default_language => "en" do
      get :show, :params => { id: project_spent(1).id }
      assert_response :redirect
      assert_redirected_to %r{#{signin_path}}
    end
  end

  test "should NoRoute on get edit as anonymous" do
    assert_raises ActionController::UrlGenerationError do
      get :edit, :params => { id: project_spent(1).id }
    end
  end

  test "should NoRoute on patch update as anonymous" do
    assert_raises ActionController::UrlGenerationError do
      put :update, params: { id: project_spent(1).id }
    end
    assert_raises ActionController::UrlGenerationError do
      patch :update, params: { id: project_spent(1).id }
    end
  end 

  test "should redirect on delete destroy as anonymous" do
    with_settings :default_language => "en" do
      delete :destroy, :params => { id: project_spent(1).id }
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

  test "should success on get new as admin" do
    @request.session[:user_id] = 1
    assert_raises ActionController::UrlGenerationError do
      get :new
    end
  end  

  test "should success on post create as admin" do
    @request.session[:user_id] = 1
    assert_raises ActionController::UrlGenerationError do
      post :create, :params => { sla_cache_spent: { } }
    end
  end

  test "should success on get show as admin" do
    @request.session[:user_id] = 1
    assert_raises ActionController::UrlGenerationError do
      get :edit, :params => { id: project_spent(1).id }
    end
  end

  test "should NoRoute on get edit as admin" do
    @request.session[:user_id] = 1
    assert_raises ActionController::UrlGenerationError do
      get :edit, :params => { id: project_spent(1).id }
    end
  end

  test "should success on patch update as admin" do
    @request.session[:user_id] = 1
    assert_raises ActionController::UrlGenerationError do
      put :update, params: { id: project_spent(1).id }
    end
    assert_raises ActionController::UrlGenerationError do
      patch :update, params: { id: project_spent(1).id }
    end
  end  

  test "should redirect on delete destroy as admin" do
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      delete :destroy, :params => { id: project_spent(1).id }
      assert_response :redirect
      assert_redirected_to sla_cache_spents_path    
    end
  end

  test "should redirect on patch purge as admin" do
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      patch :purge, params: { sla_cache_spent: { id: project_spent(1).id } }
      assert_response :redirect 
      assert_redirected_to sla_cache_spents_path  
    end
    assert_equal 0, SlaCacheSpent.count
  end  
  
  test "should redirect on patch refresh as admin" do
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      patch :refresh, params: { id: project_spent(1).id }
      assert_response :redirect
      assert_redirected_to sla_cache_spents_path      
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
      post :create, :params => { sla_cache_spent: { } }
    end
  end

  test "should redirect on get show as manager" do
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      get :show, :params => { id: project_spent(1).id }
      assert_response :redirect 
      assert_redirected_to sla_cache_spents_path 
    end
  end

  test "should NoRoute on get edit as manager" do
    @request.session[:user_id] = 2
    assert_raises ActionController::UrlGenerationError do
      get :edit, :params => { id: project_spent(1).id }
    end
  end
    
  test "should NoRoute on patch update as manager" do
    @request.session[:user_id] = 2
    assert_raises ActionController::UrlGenerationError do
      put :update, params: { id: project_spent(1).id }
    end
    assert_raises ActionController::UrlGenerationError do
      patch :update, params: { id: project_spent(1).id }
    end
  end
  
  test "should redirect on get destroy as manager" do
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      delete :destroy, :params => { id: project_spent(1).id }
      assert_response :redirect 
      assert_redirected_to sla_cache_spents_path
    end
  end

  # A manager of every project is still not allowed to purge all at once.
  test "should forbidden on patch purge as manager" do
    counts_before = spent_counts_by_project
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      patch :purge, params: { id: project_spent(1).id }
      assert_response :forbidden      
    end
    assert_equal counts_before, spent_counts_by_project
  end  
  
  test "should redirect on patch refresh as manager" do
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      patch :refresh, params: { id: project_spent(1).id }
      assert_response :redirect 
      assert_redirected_to sla_cache_spents_path
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
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      get :show, :params => { id: project_spent(1).id }
      assert_response :redirect 
      assert_redirected_to sla_cache_spents_path 
    end
  end

  test "should NoRoute on post create as developper" do
    @request.session[:user_id] = 3
    assert_raises ActionController::UrlGenerationError do
      post :create, :params => { sla_cache_spent: { } }
    end
  end  

  test "should NoRoute on get edit as developper" do
    @request.session[:user_id] = 3
    assert_raises ActionController::UrlGenerationError do
      get :edit, :params => { id: project_spent(1).id }
    end
  end
 
  test "should NoRoute on patch update as developper" do
    @request.session[:user_id] = 3
    assert_raises ActionController::UrlGenerationError do
      put :update, params: { id: project_spent(1).id }
    end
    assert_raises ActionController::UrlGenerationError do
      patch :update, params: { id: project_spent(1).id }
    end
  end

  test "should forbidden on get delete destroy as developper" do
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      delete :destroy, :params => { id: project_spent(1).id }
      assert_response :forbidden
    end
  end

  test "should forbidden on patch purge as developper" do
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      patch :purge, params: { id: project_spent(1).id }
      assert_response :forbidden      
    end
  end  
  
  test "should redirect on patch refresh as developper" do
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      patch :refresh, params: { id: project_spent(1).id }
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
    @request.session[:user_id] = 4
    with_settings :default_language => "en" do
      get :show, :params => { id: project_spent(1).id }
      assert_response :forbidden
    end
  end

  test "should NoRoute on get edit as sysadmin" do
    @request.session[:user_id] = 4
    assert_raises ActionController::UrlGenerationError do
      get :edit, :params => { id: project_spent(1).id }
    end
  end

  test "should NoRoute on patch update as sysadmin" do
    @request.session[:user_id] = 4
    assert_raises ActionController::UrlGenerationError do
      put :update, params: { id: project_spent(1).id }
    end
    assert_raises ActionController::UrlGenerationError do
      patch :update, params: { id: project_spent(1).id }
    end
  end

  test "should forbidden on get delete destroy as sysadmin" do
    @request.session[:user_id] = 4
    with_settings :default_language => "en" do
      delete :destroy, :params => { id: project_spent(1).id }
      assert_response :forbidden
    end
  end  

  test "should forbidden on patch purge as sysadmin" do
    @request.session[:user_id] = 4
    with_settings :default_language => "en" do
      patch :purge, params: { id: project_spent(1).id }
      assert_response :forbidden      
    end
  end  
  
  test "should forbidden on patch refresh as sysadmin" do
    @request.session[:user_id] = 4
    with_settings :default_language => "en" do
      patch :refresh, params: { id: project_spent(1).id }
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
    @request.session[:user_id] = 5
    with_settings :default_language => "en" do
      get :show, :params => { id: project_spent(1).id }
      assert_response :forbidden
    end
  end

  test "should NoRoute on get edit as reporter" do
    @request.session[:user_id] = 5
    assert_raises ActionController::UrlGenerationError do
      get :edit, :params => { id: project_spent(1).id }
    end
  end

  test "should NoRoute on patch update as reporter" do
    @request.session[:user_id] = 5
    assert_raises ActionController::UrlGenerationError do
      put :update, params: { id: project_spent(1).id }
    end
    assert_raises ActionController::UrlGenerationError do
      patch :update, params: { id: project_spent(1).id }
    end
  end  

  test "should forbidden on get delete destroy as reporter" do
    @request.session[:user_id] = 5
    with_settings :default_language => "en" do
      delete :destroy, :params => { id: project_spent(1).id }
      assert_response :forbidden
    end
  end

  test "should forbidden on patch purge as reporter" do
    @request.session[:user_id] = 5
    with_settings :default_language => "en" do
      patch :purge, params: { id: project_spent(1).id }
      assert_response :forbidden      
    end
  end  
  
  test "should forbidden on patch refresh as reporter" do
    @request.session[:user_id] = 5
    with_settings :default_language => "en" do
      patch :refresh, params: { id: project_spent(1).id }
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
    @request.session[:user_id] = 6
    with_settings :default_language => "en" do
      get :show, :params => { id: project_spent(1).id }
      assert_response :forbidden
    end
  end

  test "should NoRoute on get edit as other" do
    @request.session[:user_id] = 6
    assert_raises ActionController::UrlGenerationError do
      get :edit, :params => { id: project_spent(1).id }
    end
  end

  test "should NoRoute on patch update as other" do
    @request.session[:user_id] = 6
    assert_raises ActionController::UrlGenerationError do
      put :update, params: { id: project_spent(1).id }
    end
    assert_raises ActionController::UrlGenerationError do
      patch :update, params: { id: project_spent(1).id }
    end
  end  

  test "should forbidden on get delete destroy as other" do
    @request.session[:user_id] = 6
    with_settings :default_language => "en" do
      delete :destroy, :params => { id: project_spent(1).id }
      assert_response :forbidden
    end
  end
  
  test "should forbidden on patch purge as other" do
    @request.session[:user_id] = 6
    with_settings :default_language => "en" do
      patch :purge, params: { id: project_spent(1).id }
      assert_response :forbidden      
    end
  end  
  
  test "should forbidden on patch refresh as other" do
    @request.session[:user_id] = 6
    with_settings :default_language => "en" do
      patch :refresh, params: { id: project_spent(1).id }
      assert_response :forbidden
    end
  end

  ### Project-scoped permission boundaries ###

  test "anonymous is sent to login for every project-scoped spent action" do
    assert_project_spent_actions_denied(:redirect)
  end

  test "non-member is forbidden every project-scoped spent action" do
    @request.session[:user_id] = 6
    assert_project_spent_actions_denied(:forbidden)
  end

  test "member whose role lacks view_sla is forbidden every project-scoped spent action" do
    @request.session[:user_id] = 5
    assert_equal ["Reporter"], User.find(5).roles_for_project(Project.find(1)).map(&:name)
    assert_project_spent_actions_denied(:forbidden)
  end

  test "view_sla without manage_sla cannot refresh, destroy or purge spents of its project" do
    spent = project_spent(1)
    counts_before = spent_counts_by_project
    with_api_key_of(3) do |key|
      get :index, params: { project_id: "project-sla-tests-tma", format: "json", key: key }
      assert_response :success
      assert_operator response.parsed_body["total_count"], :>, 0
    end
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      patch :refresh, params: { project_id: "project-sla-tests-tma", id: spent.id }
      assert_response :forbidden
      delete :destroy, params: { project_id: "project-sla-tests-tma", id: spent.id }
      assert_response :forbidden
      patch :purge, params: { project_id: "project-sla-tests-tma" }
      assert_response :forbidden
    end
    assert_equal counts_before, spent_counts_by_project
  end

  test "project manager purge removes only the spents of that project" do
    counts_before = spent_counts_by_project
    other_projects_before = counts_before.except(1)
    assert_operator counts_before[1], :>, 0
    assert_operator other_projects_before.values.sum, :>, 0
    caches_before = SlaCache.count

    with_api_key_of(2) do |key|
      patch :purge, params: { project_id: "project-sla-tests-tma", format: "json", key: key }
      assert_response :success
    end

    assert_equal 0, SlaCacheSpent.where(project_id: 1).count
    assert_equal other_projects_before, spent_counts_by_project
    assert_equal caches_before, SlaCache.count
  end

  # Spents have no nested project route: in a project context, the actions
  # must redirect to the list filtered on that project, not raise after the
  # change is committed.
  test "project manager purge in a project context redirects to the project spent list" do
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      patch :purge, params: { project_id: "project-sla-tests-tma" }
      assert_redirected_to sla_cache_spents_path(project_id: "project-sla-tests-tma")
    end
    assert_equal 0, SlaCacheSpent.where(project_id: 1).count
  end

  test "project manager refresh in a project context redirects to the project spent list" do
    spent = project_spent(1)
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      patch :refresh, params: { project_id: "project-sla-tests-tma", id: spent.id }
      assert_redirected_to sla_cache_spents_path(project_id: "project-sla-tests-tma")
    end
    assert SlaCacheSpent.exists?(issue_id: spent.issue_id, sla_type_id: spent.sla_type_id)
  end

  test "project manager destroy in a project context redirects to the project spent list" do
    spent = project_spent(1)
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      delete :destroy, params: { project_id: "project-sla-tests-tma", id: spent.id }
      assert_redirected_to sla_cache_spents_path(project_id: "project-sla-tests-tma")
    end
    assert_not SlaCacheSpent.exists?(spent.id)
  end

  # The redirects above land on this page: it must render in a project
  # context and keep that context in its purge link and GET forms.
  test "project spent list renders in a project context and keeps the project" do
    { 2 => true, 3 => false }.each do |user_id, can_purge|
      @request.session[:user_id] = user_id
      with_settings :default_language => "en" do
        get :index, params: { project_id: "project-sla-tests-tma", "issue.status_id" => "*" }
      end
      assert_response :success
      project_ids = @controller.instance_variable_get(:@entities).map(&:project_id)
      assert_not_empty project_ids
      assert_equal [1], project_ids.uniq
      assert_select "a[href=?]", purge_sla_cache_spents_path(project_id: "project-sla-tests-tma"), can_purge ? 1 : 0
      assert_select "form#query_form input[type=hidden][name=project_id][value=project-sla-tests-tma]", 1
      assert_select "form#csv-export-form input[type=hidden][name=project_id][value=project-sla-tests-tma]", 1
    end
  end

  test "project spent CSV keeps the project context" do
    @request.session[:user_id] = 2
    get :index, params: {
      project_id: "project-sla-tests-tma",
      format: :csv,
      "issue.status_id" => "*"
    }

    assert_response :success
    assert_match %r{\Atext/csv}, response.media_type
    project_ids = @controller.instance_variable_get(:@entities).map(&:project_id)
    assert_not_empty project_ids
    assert_equal [1], project_ids.uniq
  end

  # Separate test: Rails 6.1 functional tests reuse the controller instance,
  # so a second request would keep the @project of the first one.
  test "global spent list keeps no project in its purge link and forms" do
    @request.session[:user_id] = 1
    get :index
    assert_response :success
    assert_select "a[href=?]", purge_sla_cache_spents_path, 1
    assert_select "input[name=project_id]", 0
  end

  test "project manager destroys a spent of its own project" do
    spent = project_spent(1)
    log_in_as_manager_of_project_one_only
    with_settings :default_language => "en" do
      delete :destroy, params: { id: spent.id }
      assert_response :redirect
      assert_redirected_to sla_cache_spents_path
    end
    assert_not SlaCacheSpent.exists?(spent.id)
  end

  test "project manager refreshes a spent of its own project" do
    spent = project_spent(1)
    log_in_as_manager_of_project_one_only
    with_settings :default_language => "en" do
      patch :refresh, params: { id: spent.id }
      assert_response :redirect
      assert_redirected_to sla_cache_spents_path
    end
    assert SlaCacheSpent.exists?(issue_id: spent.issue_id, sla_type_id: spent.sla_type_id)
  end

  test "project manager cannot read or change spents of a project it does not manage" do
    foreign_spent = project_spent(2)
    own_spent = project_spent(1)
    counts_before = spent_counts_by_project
    log_in_as_manager_of_project_one_only
    with_settings :default_language => "en" do
      get :index, params: { project_id: "project-sla-tests-std" }
      assert_response :forbidden
      get :show, params: { id: foreign_spent.id }
      assert_response :forbidden
      get :context_menu, params: { ids: [foreign_spent.id] }
      assert_response :forbidden
      patch :refresh, params: { id: foreign_spent.id }
      assert_response :forbidden
      patch :refresh, params: { project_id: "project-sla-tests-std", id: foreign_spent.id }
      assert_response :forbidden
      delete :destroy, params: { id: foreign_spent.id }
      assert_response :forbidden
      patch :purge, params: { project_id: "project-sla-tests-std" }
      assert_response :forbidden
      patch :purge
      assert_response :forbidden
    end
    assert_equal counts_before, spent_counts_by_project
    assert SlaCacheSpent.exists?(own_spent.id)
  end

  # The project in the URL is authorized, the row id must not escape it.
  test "project manager cannot reach a foreign spent through its own project context" do
    foreign_spent = project_spent(2)
    log_in_as_manager_of_project_one_only
    with_settings :default_language => "en" do
      get :show, params: { project_id: "project-sla-tests-tma", id: foreign_spent.id }
      assert_response :forbidden
      get :context_menu, params: { project_id: "project-sla-tests-tma", ids: [foreign_spent.id] }
      assert_response :forbidden
      patch :refresh, params: { project_id: "project-sla-tests-tma", id: foreign_spent.id }
      assert_response :forbidden
      delete :destroy, params: { project_id: "project-sla-tests-tma", id: foreign_spent.id }
      assert_response :forbidden
    end
    assert SlaCacheSpent.exists?(foreign_spent.id)
  end

  # manage_sla on project 1 passes the global authorization, and view_sla on
  # project 2 makes the foreign spent visible: only the per-project
  # management check stands between them.
  test "manager of one project cannot refresh or destroy a spent it only views in another project" do
    foreign_spent = project_spent(2)
    own_spent = project_spent(1)
    log_in_as_manager_of_project_one_only
    user = User.find_by!(login: "other")
    Member.create!(project: Project.find(2), principal: user, role_ids: [Role.find_by!(name: "Resolver").id])
    # visible? checks the issue with User.current: check both parts for this user.
    assert user.allowed_to?(:view_sla, Project.find(2))
    assert foreign_spent.issue.visible?(user)
    assert_not user.allowed_to?(:manage_sla, Project.find(2))
    counts_before = spent_counts_by_project
    updated_on_before = foreign_spent.reload.updated_on

    with_settings :default_language => "en" do
      patch :refresh, params: { id: foreign_spent.id }
      assert_response :forbidden
      delete :destroy, params: { id: foreign_spent.id }
      assert_response :forbidden
      delete :destroy, params: { ids: [own_spent.id, foreign_spent.id] }
      assert_response :forbidden
    end
    assert_equal counts_before, spent_counts_by_project
    assert_equal updated_on_before, foreign_spent.reload.updated_on

    # The same request on the managed project goes through.
    with_settings :default_language => "en" do
      delete :destroy, params: { id: own_spent.id }
      assert_response :redirect
    end
    assert_not SlaCacheSpent.exists?(own_spent.id)
  end

  test "bulk destroy mixing an allowed and a foreign spent removes neither" do
    own_spent = project_spent(1)
    foreign_spent = project_spent(2)
    log_in_as_manager_of_project_one_only
    with_settings :default_language => "en" do
      delete :destroy, params: { ids: [own_spent.id, foreign_spent.id] }
      assert_response :forbidden
    end
    assert SlaCacheSpent.exists?(own_spent.id)
    assert SlaCacheSpent.exists?(foreign_spent.id)
  end

  ### SLA module disabled ###

  test "project-scoped spent list is forbidden once the SLA module is disabled" do
    with_api_key_of(2) do |key|
      get :index, params: { project_id: "project-sla-tests-tma", format: "json", key: key }
      assert_response :success
      Project.find(1).disable_module!(:sla)
      get :index, params: { project_id: "project-sla-tests-tma", format: "json", key: key }
      assert_response :forbidden
    end
  end

  # Disabling the module through the UI purges the spents; removing the
  # module row directly keeps them, so access must depend on the module
  # itself and not only on the absence of rows.
  test "spents left on a project without the SLA module are denied even to admin and manager" do
    spent = project_spent(1)
    EnabledModule.where(project_id: 1, name: "sla").delete_all
    counts_before = spent_counts_by_project
    assert_operator counts_before[1], :>, 0

    [1, 2].each do |user_id|
      @request.session[:user_id] = user_id
      with_settings :default_language => "en" do
        get :index, params: { project_id: "project-sla-tests-tma" }
        assert_response :forbidden
        patch :purge, params: { project_id: "project-sla-tests-tma" }
        assert_response :forbidden
        get :show, params: { id: spent.id }
        assert_response :forbidden
        patch :refresh, params: { id: spent.id }
        assert_response :forbidden
        delete :destroy, params: { id: spent.id }
        assert_response :forbidden
      end
    end
    assert_equal counts_before, spent_counts_by_project
  end

  test "global spent list hides projects whose SLA module is disabled" do
    project_spents = SlaCacheSpent.where(project_id: 1).count
    assert_operator project_spents, :>, 0
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      get :index, params: { "issue.status_id" => "*" }
      assert_response :success
      count_with_module = @controller.instance_variable_get(:@entity_count)

      EnabledModule.where(project_id: 1, name: "sla").delete_all
      get :index, params: { "issue.status_id" => "*" }
      assert_response :success
      assert_equal count_with_module - project_spents, @controller.instance_variable_get(:@entity_count)
    end
  end

end
