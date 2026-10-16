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
#   Check, profile by profile, what the SLA column, filter and board icon
#   show in projects#index and admin#projects.
#
#   Fixture projects: 1 to 4 have SLAs, 5 has none (all private).
#   Fixture roles: Manager (view_sla + manage_sla), Resolver (view_sla),
#   Reporter (no SLA permission).

require_relative "../application_sla_functionals_test_case"

module SlaProjectListsTestHelper
  PROJECTS_WITH_SLA = [1, 2, 3, 4].freeze

  SLA_NAMES = {
    1 => ['SLA TMA tracker_bug_request', 'SLA TMA tracker_support_request'],
    4 => ['SLA TMA tracker_bug_request with Sla Custom Field',
          'SLA TMA tracker_support_request Sla Custom Field']
  }.freeze

  def log_in(login)
    @request.session[:user_id] = User.find_by_login(login)&.id
  end

  def list_params(extra = {})
    { display_type: 'list', set_filter: 1, f: [''], c: %w[name identifier slas] }.merge(extra)
  end

  def any_sla_filter
    { f: ['sla_id', ''], op: { sla_id: '*' } }
  end

  def no_sla_filter
    { f: ['sla_id', ''], op: { sla_id: '!*' } }
  end

  # Project ids of the rows rendered in the list.
  def listed_project_ids
    css_select('table.projects tr[id^="project-"]').map { |tr| tr['id'].delete_prefix('project-').to_i }.sort
  end

  # Project ids whose SLA cell is not empty.
  def project_ids_with_sla_cell
    css_select('table.projects tr[id^="project-"]').select { |tr|
      tr.at_css('td.slas')&.text.to_s.strip.present?
    }.map { |tr| tr['id'].delete_prefix('project-').to_i }.sort
  end

  # Project identifiers flagged with the SLA icon in the board view.
  def board_project_ids_with_icon
    css_select('#projects-index a.project.has-sla').map { |a|
      Project.find_by(identifier: a['href'].split('/').last).id
    }.sort
  end

  def sla_column_offered?
    css_select('#available_c option[value="slas"], #selected_c option[value="slas"]').any?
  end

  def sla_filter_offered?
    response.body.include?('"sla_id"')
  end
end

class SlaProjectListsProjectsControllerTest < ApplicationSlaFunctionalsTestCase
  include SlaProjectListsTestHelper
  tests ProjectsController

  def setup
    super
    User.current = nil
    set_language_if_valid 'en'
  end

  # Expected SLA visibility per profile: projects listed, and projects whose
  # SLAs are shown (cell / board icon). nil = column and filter not offered.
  PROFILES = {
    'admin'     => { listed: [1, 2, 3, 4, 5, 6], sla: [1, 2, 3, 4] },
    'manager'   => { listed: [1, 2, 3, 4, 5, 6], sla: [1, 2, 3, 4] },
    'developer' => { listed: [1, 4],          sla: [1, 4] },
    'reporter'  => { listed: [1, 2, 3, 4],    sla: nil },
    'other'     => { listed: [],              sla: nil }
  }.freeze

  PROFILES.each do |login, expected|
    test "#{login}: SLA column and filter offering in the project list" do
      log_in(login)
      get :index, params: list_params

      assert_response :success
      assert_equal expected[:listed], listed_project_ids
      assert_equal !expected[:sla].nil?, sla_column_offered?, 'SLA column offering'
      assert_equal !expected[:sla].nil?, sla_filter_offered?, 'SLA filter offering'
      assert_equal (expected[:sla] || []), project_ids_with_sla_cell
    end

    test "#{login}: SLA icons in the project board" do
      log_in(login)
      get :index, params: { display_type: 'board', set_filter: 1, f: [''] }

      assert_response :success
      assert_equal (expected[:sla] || []), board_project_ids_with_icon
    end

    next if expected[:sla].nil?

    test "#{login}: SLA filter any/none splits the visible projects" do
      log_in(login)

      get :index, params: list_params(any_sla_filter)
      assert_equal expected[:sla], listed_project_ids

      get :index, params: list_params(no_sla_filter)
      assert_equal expected[:listed] - expected[:sla], listed_project_ids
    end
  end

  test "developer: SLA cells list the names of the project SLAs" do
    log_in('developer')
    get :index, params: list_params

    SLA_NAMES.each do |project_id, names|
      assert_select "tr#project-#{project_id} td.slas", text: names.join(', ')
    end
  end

  test "developer: SLA filter values only list SLAs of visible projects" do
    log_in('developer')
    # Filter values are only embedded in the page when the filter is selected.
    get :index, params: list_params(any_sla_filter)

    values = Sla.where(id: [1, 2, 7, 8]).pluck(:name)
    hidden = Sla.where(id: [3, 4, 5, 6]).pluck(:name)
    values.each { |name| assert_includes response.body, name.to_json[1..-2] }
    hidden.each { |name| refute_includes response.body, name.to_json[1..-2] }
  end

  test "developer: SLA filter on a given SLA" do
    log_in('developer')
    get :index, params: list_params(f: ['sla_id', ''], op: { sla_id: '=' }, v: { sla_id: ['7'] })
    assert_equal [4], listed_project_ids

    get :index, params: list_params(f: ['sla_id', ''], op: { sla_id: '!' }, v: { sla_id: ['7'] })
    assert_equal [1], listed_project_ids
  end

  test "manage_sla without view_sla is enough" do
    Role.find(1).remove_permission!(:view_sla) # Manager keeps manage_sla only.
    log_in('manager')

    get :index, params: list_params
    assert sla_column_offered?
    assert_equal [1, 2, 3, 4], project_ids_with_sla_cell

    get :index, params: { display_type: 'board', set_filter: 1, f: [''] }
    assert_equal [1, 2, 3, 4], board_project_ids_with_icon
  end

  test "SLA module disabled hides the project SLAs for members" do
    Project.find(4).disable_module!(:sla)
    log_in('developer')

    get :index, params: list_params
    assert_equal [1], project_ids_with_sla_cell

    get :index, params: list_params(no_sla_filter)
    assert_equal [4], listed_project_ids

    get :index, params: { display_type: 'board', set_filter: 1, f: [''] }
    assert_equal [1], board_project_ids_with_icon
  end

  test "anonymous: no SLA column, filter or icon" do
    with_settings login_required: '0' do
      get :index, params: list_params
      assert_response :success
      refute sla_column_offered?
      refute sla_filter_offered?

      get :index, params: { display_type: 'board', set_filter: 1, f: [''] }
      assert_empty board_project_ids_with_icon
    end
  end
end

class SlaProjectListsAdminControllerTest < ApplicationSlaFunctionalsTestCase
  include SlaProjectListsTestHelper
  tests AdminController

  def setup
    super
    User.current = nil
    set_language_if_valid 'en'
  end

  test "admin: SLA column and filter offered in administration" do
    log_in('admin')
    get :projects, params: { set_filter: 1, f: [''], c: %w[name identifier slas] }

    assert_response :success
    assert sla_column_offered?
    assert sla_filter_offered?
    assert_equal [1, 2, 3, 4, 5, 6], listed_project_ids
    assert_equal [1, 2, 3, 4], project_ids_with_sla_cell
  end

  test "admin: SLA filter any/none in administration" do
    log_in('admin')

    get :projects, params: { set_filter: 1, c: %w[name slas] }.merge(any_sla_filter)
    assert_equal [1, 2, 3, 4], listed_project_ids

    get :projects, params: { set_filter: 1, c: %w[name slas] }.merge(no_sla_filter)
    assert_equal [5, 6], listed_project_ids
  end

  test "admin: project SLAs shown even when the SLA module is disabled" do
    Project.find(4).disable_module!(:sla)
    log_in('admin')
    get :projects, params: { set_filter: 1, f: [''], c: %w[name slas] }

    assert_equal [1, 2, 3, 4], project_ids_with_sla_cell
  end

  %w[manager developer reporter].each do |login|
    test "#{login}: administration project list is forbidden" do
      log_in(login)
      get :projects

      assert_response 403
    end
  end
end
