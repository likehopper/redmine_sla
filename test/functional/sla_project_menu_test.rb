# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

# File: redmine_sla/test/functional/sla_project_menu_test.rb
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

# The project "SLA" tab links to the project cache list, which requires
# :view_sla. The tab must therefore follow the same rule, so that no user is
# shown a tab that answers 403.
class SlaProjectMenuTest < ApplicationSlaFunctionalsTestCase

  tests ProjectsController

  PROJECT_IDENTIFIER = "project-sla-tests-tma"
  SLA_TAB_SELECTOR = "#main-menu a[href='/projects/#{PROJECT_IDENTIFIER}/sla/caches']"

  def setup
    super
    User.current = nil
    set_language_if_valid 'en'
    @project = Project.find_by!(identifier: PROJECT_IDENTIFIER)
    # User "other" has no membership in the fixtures.
    @user = User.find_by!(login: "other")
    @request.session[:user_id] = @user.id
  end

  test "SLA tab is shown to a member with view_sla" do
    add_membership(:view_sla)

    get :show, params: { id: PROJECT_IDENTIFIER }
    assert_response :success
    assert_select SLA_TAB_SELECTOR, 1
  end

  test "SLA tab is shown to a member with view_sla and manage_sla" do
    add_membership(:view_sla, :manage_sla)

    get :show, params: { id: PROJECT_IDENTIFIER }
    assert_response :success
    assert_select SLA_TAB_SELECTOR, 1
  end

  test "SLA tab is hidden from a member with manage_sla only" do
    add_membership(:manage_sla)

    get :show, params: { id: PROJECT_IDENTIFIER }
    assert_response :success
    assert_select SLA_TAB_SELECTOR, 0
  end

  test "SLA tab is hidden from a member without SLA permission" do
    add_membership

    get :show, params: { id: PROJECT_IDENTIFIER }
    assert_response :success
    assert_select SLA_TAB_SELECTOR, 0
  end

  test "SLA tab is hidden when the SLA module is disabled" do
    add_membership(:view_sla, :manage_sla)
    @project.enabled_modules.where(name: "sla").delete_all

    get :show, params: { id: PROJECT_IDENTIFIER }
    assert_response :success
    assert_select SLA_TAB_SELECTOR, 0
  end

  test "SLA tab is hidden from an administrator when the SLA module is disabled" do
    @request.session[:user_id] = User.find_by!(login: "admin").id
    @project.enabled_modules.where(name: "sla").delete_all

    get :show, params: { id: PROJECT_IDENTIFIER }
    assert_response :success
    assert_select SLA_TAB_SELECTOR, 0
  end

  test "SLA tab is hidden from anonymous and non-members on a public project" do
    make_project_public
    with_settings login_required: '0' do
      [nil, @user.id].each do |user_id|
        @request.session[:user_id] = user_id
        get :show, params: { id: PROJECT_IDENTIFIER }
        assert_response :success
        assert_select SLA_TAB_SELECTOR, 0
      end
    end
  end

  test "SLA tab is hidden from a view_sla member of another project" do
    make_project_public
    role = Role.create!(name: "SLA menu test other project", permissions: [:view_project, :view_sla])
    Member.create!(project: Project.find(2), principal: @user, role_ids: [role.id])
    assert @user.reload.allowed_to?(:view_sla, Project.find(2))

    get :show, params: { id: PROJECT_IDENTIFIER }
    assert_response :success
    assert_select SLA_TAB_SELECTOR, 0

    get :show, params: { id: "project-sla-tests-std" }
    assert_response :success
    assert_select "#main-menu a[href='/projects/project-sla-tests-std/sla/caches']", 1
  end

  ### Project settings SLA tab ###

  SETTINGS_TAB_SELECTOR = "#content .tabs a#tab-sla"

  test "settings SLA tab lists the project assignments to a manager" do
    @request.session[:user_id] = User.find_by!(login: "manager").id

    get :settings, params: { id: PROJECT_IDENTIFIER, tab: "sla" }
    assert_response :success
    assert_select SETTINGS_TAB_SELECTOR, 1
    assert_select "#tab-content-sla td.sla", text: Sla.find(1).name
    # SLA 3 is only assigned to project 2.
    assert_select "#tab-content-sla td.sla", text: Sla.find(3).name, count: 0
  end

  test "settings SLA tab is hidden from a member who can edit the project without manage_sla" do
    add_membership(:edit_project, :view_sla)
    assert @user.allowed_to?(:edit_project, @project)

    get :settings, params: { id: PROJECT_IDENTIFIER, tab: "sla" }
    assert_response :success
    assert_select SETTINGS_TAB_SELECTOR, 0
    assert_select "#tab-content-sla", 0
    assert_not response.body.include?(Sla.find(1).name), "settings page exposes the project SLA"
  end

  test "settings SLA tab is hidden when the SLA module is disabled" do
    @request.session[:user_id] = User.find_by!(login: "manager").id
    @project.disable_module!(:sla)

    get :settings, params: { id: PROJECT_IDENTIFIER, tab: "sla" }
    assert_response :success
    assert_select SETTINGS_TAB_SELECTOR, 0
    assert_not response.body.include?(Sla.find(1).name), "settings page exposes the project SLA"
  end

  test "settings SLA tab is hidden from a manager of another project" do
    add_membership(:edit_project)
    role = Role.create!(name: "SLA settings test other project", permissions: [:view_project, :manage_sla])
    Member.create!(project: Project.find(2), principal: @user, role_ids: [role.id])

    get :settings, params: { id: PROJECT_IDENTIFIER, tab: "sla" }
    assert_response :success
    assert_select SETTINGS_TAB_SELECTOR, 0
    assert_not response.body.include?(Sla.find(1).name), "settings page exposes the project SLA"
  end

  private

  def make_project_public
    @project.update_column(:is_public, true)
    assert Project.find(@project.id).visible?(User.anonymous)
  end

  def add_membership(*sla_permissions)
    role = Role.create!(
      name: "SLA menu test #{sla_permissions.join('-').presence || 'none'}",
      permissions: [:view_project] + sla_permissions
    )
    Member.create!(project: @project, principal: @user, role_ids: [role.id])
  end

end
