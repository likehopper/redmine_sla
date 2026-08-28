# frozen_string_literal: true

# File: redmine_sla/test/integration/sla_caches_test.rb
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

require_relative "../application_sla_integration_test_case"

# End-to-end check of the "Explain" feature through the real routing table
# and a real session login (unlike the functional tests, which dispatch
# straight to the controller action).
class SlaCachesTest < ApplicationSlaIntegrationTestCase

  def setup
    User.current = nil
    set_language_if_valid 'en'
  end

  test "should return success on get sla_explain as manager" do
    log_user('manager', 'manager')
    issue_id = SlaCache.where(project: 1).order(:id).first.issue_id
    get "/issues/#{issue_id}/sla_explain"
    assert_response :success
  end

  test "should return forbidden on get sla_explain as developer with view_sla only" do
    log_user('developer', 'developer')
    issue_id = SlaCache.where(project: 1).order(:id).first.issue_id
    get "/issues/#{issue_id}/sla_explain"
    assert_response :forbidden
  end

end
