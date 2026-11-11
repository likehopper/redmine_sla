# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

# File: redmine_sla/test/functional/sla_levels_controller_test.rb
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

class SlaLevelsControllerTest < ApplicationSlaFunctionalsTestCase

  def setup
    super
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

  ### As admin #1 ###

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

  # Regression: a block column (here the description) used to make the list
  # fail with a 500 error, its partial reading an undefined `query`.
  test "should get success on index with the description block column as admin" do
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      get :index, :params => {:set_filter => 1, :c => ['name', 'description']}
      assert_response :success
      # The description row spans the checkbox, name and buttons cells
      assert_select 'tr#entity_id_1 + tr td.description[colspan="3"]',
        :text => /#{Regexp.escape(SlaLevel.find(1).description)}/
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

  test "should show every sla type with no toggle when the level has no terms yet" do
    @request.session[:user_id] = 1
    empty_level = SlaLevel.create!(name: "Empty level for masking test", sla_id: 3, sla_calendar_id: 1)

    get(:sla_terms, :params => {:id => empty_level.id})
    assert_response :success
    assert_select 'a', :text => l('sla_label.sla_level_term.show_hidden_types'), :count => 0
    assert_select '.sla-type-hidden', :count => 0
    assert_select '#sla-level-terms-table thead th', :text => 'GTI'
    assert_select '#sla-level-terms-table thead th', :text => 'GTR'
  end

  test "should hide sla types with no terms behind a toggle" do
    @request.session[:user_id] = 1
    # Fixture level 2 ("TMA - Support HO") only has terms for GTI (sla_type_id 1);
    # GTR (sla_type_id 2) has none and should collapse behind the toggle.
    get(:sla_terms, :params => {:id => 2})
    assert_response :success
    assert_select 'a', :text => l('sla_label.sla_level_term.show_hidden_types'), :count => 1
    assert_select '#sla-level-terms-table thead th.sla-type-hidden', :text => 'GTR'
    assert_select '#sla-level-terms-table thead th:not(.sla-type-hidden)', :text => 'GTI'
  end

  test "should display nested term validation errors" do
    @request.session[:user_id] = 1
    term = SlaLevelTerm.find(1)
    cache_ids = SlaCache.unscoped.order(:id).pluck(:id)
    deletes = []
    subscriber = lambda do |*args|
      sql = args.last[:sql]
      deletes << sql if sql.match?(/\ADELETE FROM ["`]?sla_caches["`]?/i)
    end

    ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
      patch :update, params: {
        id: 1,
        sla_level: {
          sla_level_terms_attributes: {
            "1" => {
              "1" => { id: term.id, term: "-1" }
            }
          }
        }
      }
    end

    assert_response :success
    assert_select "#errorExplanation"
    assert_empty deletes
    assert_equal cache_ids, SlaCache.unscoped.order(:id).pluck(:id)
    assert_not_equal(-1, term.reload.term)
  end

  ### As manager #2 ###

  test "should return success on get index as manager" do
    @request.session[:user_id] = 2
    with_settings :default_language => "en" do
      get :index
      assert_response :success
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

  ### As developper #3 ###

  test "should return success on get index as developper" do
    @request.session[:user_id] = 3
    with_settings :default_language => "en" do
      get :index
      assert_response :success
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

  ### As sysadmin #4 ###

  test "should return success on get index as sysadmin" do
    @request.session[:user_id] = 4
    with_settings :default_language => "en" do
      get :index
      assert_response :success
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

  test "should scope project index to SLA levels used by a Resolver project" do
    @request.session[:user_id] = 3

    get :index, params: {project_id: "project-sla-tests-tma"}

    assert_response :success
    assert_select "#entity_id_1", count: 1
    assert_select "#entity_id_2", count: 1
    assert_select "#entity_id_3", count: 0
    assert_select 'a[href="/projects/project-sla-tests-tma/sla/levels/1"]', title: "Show"
  end

  test "should forbid Resolver access to another project SLA level index" do
    @request.session[:user_id] = 3

    get :index, params: {project_id: "project-sla-tests-std"}

    assert_response :forbidden
  end

  test "should forbid showing a SLA level outside the requested project" do
    @request.session[:user_id] = 3

    get :show, params: {project_id: "project-sla-tests-tma", id: 3}

    assert_response :forbidden
  end

  ### Access audit: SLA levels are managed by administrators only ###

  test "should render new and context menu on SLA levels as admin" do
    @request.session[:user_id] = 1
    get :new
    assert_response :success
    get :context_menu, params: { ids: [1] }
    assert_response :success
    assert_select "a[href=?]", edit_sla_level_path(1)
  end

  test "should create, update with nested terms, delete and bulk delete SLA levels as admin" do
    @request.session[:user_id] = 1
    assert_difference "SlaLevel.count", 1 do
      post :create, params: { sla_level: { name: "Created SLA level", sla_id: 3, sla_calendar_id: 1 } }
    end
    assert_redirected_to sla_levels_path
    patch :update, params: { id: 1, sla_level: { name: "Updated SLA level" } }
    assert_redirected_to sla_levels_path
    assert_equal "Updated SLA level", SlaLevel.find(1).name
    assert_difference "SlaLevelTerm.count", -1 do
      patch :update, params: { id: 1, sla_level: { sla_level_terms_attributes: { "1" => { "1" => { id: 1, term: "" } } } } }
    end
    assert_not SlaLevelTerm.exists?(1)
    deletables = create_deletable_sla_levels
    assert_difference "SlaLevel.count", -1 do
      delete :destroy, params: { id: deletables.first.id }
    end
    assert_difference "SlaLevel.count", -2 do
      delete :destroy, params: { ids: deletables.drop(1).map(&:id) }
    end
    assert_redirected_to sla_levels_path
  end

  # Users 2 and 3 may view levels of their projects (manage_sla / view_sla), user 5 has no SLA permission.
  { "anonymous" => nil, "project SLA manager" => 2, "Resolver with view_sla" => 3, "reporter without SLA permission" => 5 }.each do |label, user_id|
    test "should deny new, terms form and context menu on SLA levels to #{label}" do
      @request.session[:user_id] = user_id
      get :new
      assert_access_denied(user_id)
      get :sla_terms, params: { id: 1 }
      assert_access_denied(user_id)
      get :context_menu, params: { ids: [1] }
      assert_access_denied(user_id)
    end

    test "should deny SLA level writes to #{label} without changing data" do
      deletables = create_deletable_sla_levels
      term_attributes = SlaLevelTerm.find(1).attributes
      assert_no_difference "SlaLevelTerm.count" do
        assert_denied_without_change(user_id, SlaLevel.find(1)) do
          post :create, params: { sla_level: { name: "Denied SLA level", sla_id: 3, sla_calendar_id: 1 } }
          assert_access_denied(user_id)
          patch :update, params: { id: 1, sla_level: { name: "Denied SLA level change" } }
          assert_access_denied(user_id)
          patch :update, params: { id: 1, sla_level: { sla_level_terms_attributes: { "1" => { "1" => { id: 1, term: "" } } } } }
          assert_access_denied(user_id)
          delete :destroy, params: { id: deletables.first.id }
          assert_access_denied(user_id)
          delete :destroy, params: { ids: deletables.map(&:id) }
          assert_access_denied(user_id)
        end
      end
      assert_equal term_attributes, SlaLevelTerm.find(1).attributes
      assert_equal deletables.size, SlaLevel.where(id: deletables.map(&:id)).count
    end
  end

  # Fresh levels without terms or caches, so a leaked destroy would really delete them.
  def create_deletable_sla_levels
    sla = Sla.create!(name: "SLA for deletable levels")
    Array.new(3) { |index| SlaLevel.create!(name: "Deletable SLA level #{index}", sla: sla, sla_calendar_id: index + 1) }
  end

end
