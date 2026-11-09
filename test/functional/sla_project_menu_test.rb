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

  private

  def add_membership(*sla_permissions)
    role = Role.create!(
      name: "SLA menu test #{sla_permissions.join('-').presence || 'none'}",
      permissions: [:view_project] + sla_permissions
    )
    Member.create!(project: @project, principal: @user, role_ids: [role.id])
  end

end
