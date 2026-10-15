# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Redmine SLA - service level agreement plugin
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

# File: redmine_sla/test/functional/sla_project_lists_controller_test.rb
# Purpose:
#   Render the SLA column/filter in projects#index and admin#projects.

require_relative "../application_sla_functionals_test_case"

class SlaProjectListsProjectsControllerTest < ApplicationSlaFunctionalsTestCase
  tests ProjectsController

  def setup
    super
    User.current = nil
    set_language_if_valid 'en'
  end

  test "member sees the SLA column in the project list" do
    @request.session[:user_id] = 3
    get :index, params: {
      display_type: 'list', set_filter: 1,
      f: ['sla_id', ''], op: { sla_id: '*' }, c: %w[name slas]
    }

    assert_response :success
    assert_select 'table.projects td.slas', text: /SLA TMA tracker_bug_request/
    assert_select 'table.projects tr#project-1'
    assert_select 'table.projects tr#project-4'
  end

  test "board view shows the SLA icon only on projects with visible SLAs" do
    @request.session[:user_id] = 2 # Manager in projects 1 to 5.
    get :index, params: { display_type: 'board', set_filter: 1, f: [''] }

    assert_response :success
    assert_select '#projects-index a.project.has-sla', 4
    assert_select '#projects-index a.project.has-sla[href=?]', '/projects/another-project-without-sla', 0
  end

  test "board view shows no SLA icon without SLA permission" do
    @request.session[:user_id] = 5
    get :index, params: { display_type: 'board', set_filter: 1, f: [''] }

    assert_response :success
    assert_select '#projects-index a.project', minimum: 1
    assert_select '#projects-index a.project.has-sla', 0
  end

  test "user without SLA permission gets no SLA column" do
    @request.session[:user_id] = 5
    get :index, params: { display_type: 'list', set_filter: 1, c: %w[name slas] }

    assert_response :success
    assert_select 'table.projects td.slas', 0
  end
end

class SlaProjectListsAdminControllerTest < ApplicationSlaFunctionalsTestCase
  tests AdminController

  def setup
    super
    User.current = nil
    set_language_if_valid 'en'
  end

  test "admin lists projects with SLA" do
    @request.session[:user_id] = 1
    get :projects, params: {
      set_filter: 1, f: ['sla_id', ''], op: { sla_id: '*' }, c: %w[name identifier slas]
    }

    assert_response :success
    assert_select 'table.projects td.slas', text: /SLA Managed Services Standard/
    assert_select 'table.projects tr#project-5', 0
  end

  test "admin lists projects without SLA" do
    @request.session[:user_id] = 1
    get :projects, params: {
      set_filter: 1, f: ['sla_id', ''], op: { sla_id: '!*' }, c: %w[name slas]
    }

    assert_response :success
    assert_select 'table.projects tr#project-5'
    assert_select 'table.projects tr#project-1', 0
  end
end
