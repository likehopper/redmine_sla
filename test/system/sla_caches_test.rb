# frozen_string_literal: true

# File: redmine_sla/test/system/sla_caches_test.rb
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

require_relative "../application_sla_system_test_case"

class SlaCachesSystemTest < ApplicationSlaSystemTestCase

  test "explain link is visible and navigable for a manager" do
    sla_cache = SlaCache.where(project: 1).order(:id).first
    log_user('manager', 'manager')

    visit "/issues/#{sla_cache.issue_id}"
    assert_selector 'a', text: l(:button_sla_explain)

    click_link l(:button_sla_explain)
    assert_current_path sla_explain_issue_path(sla_cache.issue_id)
    assert_text l(:label_sla_explain_title)
  end

  test "explain link is hidden for a user with view_sla only" do
    sla_cache = SlaCache.where(project: 1).order(:id).first
    log_user('developer', 'developer')

    visit "/issues/#{sla_cache.issue_id}"
    assert_no_selector 'a', text: l(:button_sla_explain)
  end

end
