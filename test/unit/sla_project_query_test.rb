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

# File: redmine_sla/test/unit/sla_project_query_test.rb
# Purpose:
#   Cover the SLA column and filter added to the project lists
#   (ProjectQuery / ProjectAdminQuery), including permission checks.
#
# Redmine SLA - Redmine's Plugin

require File.expand_path('../../application_sla_units_test_case', __FILE__)

class SlaProjectQueryTest < ApplicationSlaUnitsTestCase

  def teardown
    User.current = nil
    super
  end

  def project_ids_for(query_class, operator, values = nil)
    query = query_class.new(name: '_')
    query.filters = {}
    query.add_filter('sla_id', operator, values)
    query.results_scope.pluck(:id).sort
  end

  test "admin sees the SLA column and filter on both project lists" do
    User.current = User.find(1)

    [ProjectQuery, ProjectAdminQuery].each do |query_class|
      query = query_class.new
      assert_includes query.available_columns.map(&:name), :slas
      assert query.available_filters.key?('sla_id')
    end
  end

  test "admin filters projects with and without SLA" do
    User.current = User.find(1)

    assert_equal [1, 2, 3, 4], project_ids_for(ProjectAdminQuery, '*')
    assert_equal [5, 6], project_ids_for(ProjectAdminQuery, '!*')
    assert_equal [4], project_ids_for(ProjectAdminQuery, '=', ['7'])
    assert_equal [1, 2, 3, 5, 6], project_ids_for(ProjectAdminQuery, '!', ['7', '8'])
  end

  test "admin filter values list every SLA" do
    User.current = User.find(1)

    assert_equal Sla.order(:name).pluck(:id).map(&:to_s),
                 ProjectAdminQuery.new.project_sla_values.map(&:last)
  end

  test "column lists distinct SLAs sorted by name" do
    User.current = User.find(1)
    column = ProjectQuery.new.available_columns.detect { |c| c.name == :slas }

    assert_equal ['SLA TMA tracker_bug_request', 'SLA TMA tracker_support_request'],
                 column.value_object(Project.find(1)).map(&:name)
    assert_empty column.value_object(Project.find(5))
  end

  test "results scope preloads SLA assignments when the column is displayed" do
    User.current = User.find(1)
    query = ProjectAdminQuery.new(name: '_')
    query.column_names = [:name, :slas]

    project = query.results_scope.detect { |p| p.id == 1 }
    assert project.association(:sla_project_trackers).loaded?
  end

  test "member with view_sla only matches projects where SLAs are visible" do
    User.current = User.find(3) # Resolver (view_sla) in projects 1 and 4.

    assert_equal [1, 4], project_ids_for(ProjectQuery, '*')
    assert_equal %w[1 2 7 8], ProjectQuery.new.project_sla_values.map(&:last).sort
  end

  test "projects without SLA permission behave as having no SLA" do
    User.current = User.find(3)
    Project.find(4).enabled_modules.where(name: 'sla').delete_all

    assert_equal [1], project_ids_for(ProjectQuery, '*')
    assert_includes project_ids_for(ProjectQuery, '!*'), 4
    assert_empty Project.find(4).visible_slas
    assert_equal %w[1 2], ProjectQuery.new.project_sla_values.map(&:last).sort
  end

  test "column and filter are hidden without any SLA permission" do
    [User.find(5), User.anonymous].each do |user|
      User.current = user
      query = ProjectQuery.new

      refute_includes query.available_columns.map(&:name), :slas
      refute query.available_filters.key?('sla_id')
      assert_empty Project.find(1).visible_slas(user)
    end
  end

  test "css classes flag projects with visible SLAs" do
    User.current = User.find(3) # view_sla in projects 1 and 4.

    assert_includes Project.find(1).css_classes.split, 'has-sla'
    refute_includes Project.find(2).css_classes.split, 'has-sla'
    refute_includes Project.find(5).css_classes.split, 'has-sla'

    User.current = User.find(1)
    assert_includes Project.find(2).css_classes.split, 'has-sla'
    refute_includes Project.find(5).css_classes.split, 'has-sla'
  end

  test "board display preloads SLA assignments" do
    User.current = User.find(3)
    query = ProjectQuery.new(name: '_')
    query.display_type = 'board'

    project = query.results_scope.detect { |p| p.id == 1 }
    assert project.association(:sla_project_trackers).loaded?
    assert project.association(:enabled_modules).loaded?
  end

end
