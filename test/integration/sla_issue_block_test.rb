# frozen_string_literal: true
# File: redmine_sla/test/integration/sla_issue_block_test.rb
# SPDX-License-Identifier: GPL-2.0-or-later

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

require_relative '../application_sla_integration_test_case'

# Rendering and calculation boundaries of the issue SLA block.
class SlaIssueBlockTest < ApplicationSlaIntegrationTestCase
  def setup
    super
    User.current = nil
    set_language_if_valid 'en'
    @issue = Issue.find(SlaCache.find_by!(sla_level_id: 1).issue_id)
  end

  %w[admin manager].each do |login|
    test "#{login}: a tracker without SLA hides the block without calculating a level" do
      issue = Issue.find_by!(project_id: 1, tracker_id: 2)
      assert_not SlaProjectTracker.exists?(project_id: issue.project_id, tracker_id: issue.tracker_id)
      log_user(login, login)
      Issue.any_instance.expects(:get_sla_cache).never

      get "/issues/#{issue.id}"
      assert_response :success
      assert_select 'div.sla.attribute', 0
    end
  end

  test 'an SLA assigned to the same tracker in another project does not show the block' do
    issue = Issue.find_by!(subject: 'Issue in a project without SLA')
    issue.project.enable_module!(:sla)
    assert SlaProjectTracker.where(tracker_id: issue.tracker_id).exists?
    assert_not SlaProjectTracker.exists?(project_id: issue.project_id, tracker_id: issue.tracker_id)
    log_user('admin', 'admin')
    Issue.any_instance.expects(:get_sla_cache).never

    get "/issues/#{issue.id}"
    assert_response :success
    assert_select 'div.sla.attribute', 0
  end

  test 'a user without view permission skips assignment lookup and calculation' do
    log_user('reporter', 'reporter')
    SlaProjectTracker.expects(:exists?).never
    Issue.any_instance.expects(:get_sla_cache).never

    get "/issues/#{@issue.id}"
    assert_response :success
    assert_select 'div.sla.attribute', 0
  end

  test 'a disabled SLA module skips assignment lookup and calculation' do
    @issue.project.disable_module!(:sla)
    log_user('admin', 'admin')
    SlaProjectTracker.expects(:exists?).never
    Issue.any_instance.expects(:get_sla_cache).never

    get "/issues/#{@issue.id}"
    assert_response :success
    assert_select 'div.sla.attribute', 0
  end

  { 'manager' => 1, 'developer' => 0 }.each do |login, block_count|
    test "#{login}: an assigned SLA with no matching level offers explanations only to managers" do
      assignment = SlaProjectTracker.find_by!(project_id: @issue.project_id, tracker_id: @issue.tracker_id)
      assignment.update!(sla: Sla.create!(name: 'SLA without applicable levels'))
      assert_nil Issue.find(@issue.id).get_sla_cache
      log_user(login, login)

      get "/issues/#{@issue.id}"
      assert_response :success
      assert_select 'div.sla.attribute', block_count
      assert_select "div.sla.attribute a[href='/issues/#{@issue.id}/sla_explain']", block_count
    end
  end

  test 'a reader sees the applicable level without a management link' do
    log_user('developer', 'developer')

    get "/issues/#{@issue.id}"
    assert_response :success
    assert_select 'div.sla.attribute', 1
    assert_select 'div.sla.attribute a[href="/sla/levels/1"]'
    assert_select "div.sla.attribute a[href='/issues/#{@issue.id}/sla_explain']", 0
  end
end
