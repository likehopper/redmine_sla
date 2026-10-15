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

# File: redmine_sla/test/documentation/sla_project_lists_doc_test.rb
# Purpose:
#   Browse the project lists with each profile, check in Chromium what is
#   shown (SLA column, filter, board icon) and take the screenshots used by
#   doc/PROJECT_LISTS.md (tmp/redmine_sla/screenshots/project-lists/).
#
#   Unlike the example suites, it runs on the SLA test fixtures. Fixtures
#   are reloaded before each test (non-transactional) so that it can run
#   before or after the example suites, which empty these tables.

require_relative '../application_sla_system_test_case'
require_relative '../helpers/sla_documentation_helper'

class SlaProjectListsDocTest < ApplicationSlaSystemTestCase
  include SlaDocumentationHelperTest

  self.use_transactional_tests = false

  LIST_COLUMNS = %w[name identifier slas].freeze

  def setup
    super
    @current_suite = 'project-lists'
  end

  def teardown
    User.current = nil
    super
  end

  def list_path(base, filter: nil)
    params = [['set_filter', '1'], ['display_type', 'list']]
    if filter
      params += [['f[]', 'sla_id'], ['op[sla_id]', filter]]
    else
      params << ['f[]', '']
    end
    params += LIST_COLUMNS.map { |c| ['c[]', c] }
    "#{base}?#{URI.encode_www_form(params)}"
  end

  def board_path
    "/projects?#{URI.encode_www_form([['set_filter', '1'], ['display_type', 'board'], ['f[]', '']])}"
  end

  # Board links carrying the SLA icon, checked through the rendered
  # ::after background so that a missing stylesheet would be detected.
  def board_identifiers_with_icon
    page.evaluate_script(<<~JS)
      Array.from(document.querySelectorAll('#projects-index a.project'))
        .filter(function(a) {
          return window.getComputedStyle(a, '::after').backgroundImage.indexOf('sla_16') !== -1;
        })
        .map(function(a) { return a.getAttribute('href').split('/').pop(); })
        .sort()
    JS
  end

  def identifiers(ids)
    Project.where(id: ids).pluck(:identifier).sort
  end

  test "01 administrator: projects with and without SLA" do
    log_user('admin', 'admin')

    visit list_path('/admin/projects', filter: '*')
    assert_selector 'table.projects tr[id^="project-"]', count: 4
    assert_selector 'table.projects td.slas', text: 'SLA Managed Services Standard'
    take_doc_screenshot '01-01-admin-projects-with-sla.png'

    visit list_path('/admin/projects', filter: '!*')
    assert_selector 'table.projects tr[id^="project-"]', count: 1
    assert_selector 'table.projects tr#project-5'
    take_doc_screenshot '01-02-admin-projects-without-sla.png'
  end

  test "02 manager (view and manage SLA): every project SLA" do
    log_user('manager', 'manager')

    visit list_path('/projects')
    assert_selector 'table.projects td.slas', text: /\S/, count: 4
    take_doc_screenshot '02-01-manager-projects-list.png'

    visit board_path
    assert_equal identifiers(1..4), board_identifiers_with_icon
    take_doc_screenshot '02-02-manager-projects-board.png'
  end

  test "03 developer (view SLA in two projects): only those projects" do
    log_user('developer', 'developer')

    visit list_path('/projects')
    assert_selector 'table.projects tr[id^="project-"]', count: 2
    assert_selector 'table.projects td.slas', text: /\S/, count: 2
    take_doc_screenshot '03-01-developer-projects-list.png'

    visit board_path
    assert_equal identifiers([1, 4]), board_identifiers_with_icon
    take_doc_screenshot '03-02-developer-projects-board.png'
  end

  test "04 reporter (no SLA permission): nothing about SLA" do
    log_user('reporter', 'reporter')

    visit list_path('/projects')
    assert_selector 'table.projects tr[id^="project-"]', count: 4
    assert_no_selector 'table.projects th', text: 'SLA'
    assert_no_selector 'table.projects td.slas'
    take_doc_screenshot '04-01-reporter-projects-list.png'

    visit board_path
    assert_selector '#projects-index a.project', count: 4
    assert_empty board_identifiers_with_icon
    take_doc_screenshot '04-02-reporter-projects-board.png'
  end
end
