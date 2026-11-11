# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

# File: redmine_sla/test/functional/sla_level_terms_controller_test.rb
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

class SlaLevelTermsControllerTest < ApplicationSlaFunctionalsTestCase

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

  test "should NoRoute on get edit as anonymous" do
    assert_raises ActionController::UrlGenerationError do
      get :edit, :params => { id: 1 }
    end
  end   

  ### As admin #1 ###

  test "should get success on index as admin" do
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      get :index
      assert_response :success
      # links to visible issues
      assert_select 'a[href="/sla/level_terms/1"]', :title => "Show"
      # assert_select 'a[href="/sla/level_terms/1/edit"]', :title => "Edit"
      assert_select_not 'a', { href: "/sla/level_terms/1/edit", title: "Edit" }, "The 'Edit' link should not be present"
      assert_select 'a[href="/sla/level_terms/1"]', :title => "Delete", :method => "delete"
    end
  end

  test "should return success on get show as admin" do
    @request.session[:user_id] = 1
    with_settings :default_language => "en" do
      get(:show, :params => {:id => 1})
      assert_response :success
    end
  end

  test "should NoRoute on get edit as admin" do
    @request.session[:user_id] = 1
    assert_raises ActionController::UrlGenerationError do
      get :edit, :params => { id: 1 }
    end
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

  test "should NoRoute on get edit as manager" do
    @request.session[:user_id] = 2
    assert_raises ActionController::UrlGenerationError do
      get :edit, :params => { id: 1 }
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

  test "should NoRoute on get edit as developper" do
    @request.session[:user_id] = 3
    assert_raises ActionController::UrlGenerationError do
      get :edit, :params => { id: 1 }
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

  test "should NoRoute on get edit as sysadmin" do
    @request.session[:user_id] = 4
    assert_raises ActionController::UrlGenerationError do
      get :edit, :params => { id: 1 }
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

  test "should NoRoute on get edit as reporter" do
    @request.session[:user_id] = 5
    assert_raises ActionController::UrlGenerationError do
      get :edit, :params => { id: 1 }
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

  test "should NoRoute on get edit as other" do
    @request.session[:user_id] = 6
    assert_raises ActionController::UrlGenerationError do
      get :edit, :params => { id: 1 }
    end
  end

  ### Access audit: SLA level terms are managed by administrators only ###

  # Terms are only created or changed through the SLA level form.
  test "should not route create or update for SLA level terms" do
    @request.session[:user_id] = 1
    assert_raises(ActionController::UrlGenerationError) { post :create, params: { sla_level_term: { term: 1 } } }
    assert_raises(ActionController::UrlGenerationError) { patch :update, params: { id: 1, sla_level_term: { term: 1 } } }
  end

  test "should render context menu on SLA level terms as admin" do
    @request.session[:user_id] = 1
    get :context_menu, params: { ids: [1] }
    assert_response :success
    assert_select "a[href=?]", sla_level_term_path(1)
  end

  test "should delete and bulk delete SLA level terms as admin" do
    @request.session[:user_id] = 1
    deletables = deletable_sla_level_terms
    assert_difference "SlaLevelTerm.count", -1 do
      delete :destroy, params: { id: deletables.first.id }
    end
    assert_difference "SlaLevelTerm.count", -2 do
      delete :destroy, params: { ids: deletables.drop(1).map(&:id) }
    end
    assert_redirected_to sla_level_terms_path
  end

  { "anonymous" => nil, "project SLA manager" => 2, "reporter without SLA permission" => 5 }.each do |label, user_id|
    test "should deny context menu on SLA level terms to #{label}" do
      @request.session[:user_id] = user_id
      get :context_menu, params: { ids: [1] }
      assert_access_denied(user_id)
    end

    test "should deny SLA level term deletion to #{label} without changing data" do
      deletables = deletable_sla_level_terms
      assert_denied_without_change(user_id, deletables.first) do
        delete :destroy, params: { id: deletables.first.id }
        assert_access_denied(user_id)
        delete :destroy, params: { ids: deletables.map(&:id) }
        assert_access_denied(user_id)
      end
      assert_equal deletables.size, SlaLevelTerm.where(id: deletables.map(&:id)).count
    end
  end

  # Terms have no dependents, so fixture rows are deletable.
  def deletable_sla_level_terms
    SlaLevelTerm.order(:id).limit(3).to_a
  end

end
