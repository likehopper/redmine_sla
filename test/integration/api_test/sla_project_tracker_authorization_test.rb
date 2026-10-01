# frozen_string_literal: true
# File: redmine_sla/test/integration/api_test/sla_project_tracker_authorization_test.rb
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

require_relative '../../application_sla_api_test_case'

class Redmine::ApiTest::SlaProjectTrackerAuthorizationTest < ApplicationSlaApiTestCase
  def setup
    super
    Member.where(user_id: 2).where.not(project_id: 1).destroy_all
  end

  test 'anonymous and read only users cannot create assignments' do
    [nil, 'developer'].each do |login|
      assert_no_difference 'SlaProjectTracker.count' do
        post '/sla/project_trackers.json', params: {sla_project_tracker: attributes_for(1)},
          headers: login ? credentials(login) : {}
      end
      assert_response(login ? :forbidden : :unauthorized)
    end
  end

  test 'manager cannot create assignments in an unauthorized project through either route' do
    ['/sla/project_trackers.json', '/projects/2/sla/trackers.json'].each do |path|
      assert_no_difference 'SlaProjectTracker.count' do
        post path, params: {sla_project_tracker: attributes_for(2)}, headers: credentials('manager')
      end
      assert_response :forbidden
    end
  end

  test 'manager cannot move an assignment to an unauthorized project' do
    link = SlaProjectTracker.find_by!(project_id: 1, tracker_id: 1)
    patch "/sla/project_trackers/#{link.id}.json",
      params: {sla_project_tracker: {project_id: 2}}, headers: credentials('manager')
    assert_response :forbidden
    assert_equal 1, link.reload.project_id
  end

  test 'manager cannot update or delete an unauthorized assignment by direct id' do
    link = SlaProjectTracker.find_by!(project_id: 2)
    original = link.attributes
    patch "/sla/project_trackers/#{link.id}.json",
      params: {sla_project_tracker: {project_id: 1}}, headers: credentials('manager')
    assert_response :not_found
    assert_equal original, link.reload.attributes
    assert_no_difference 'SlaProjectTracker.count' do
      delete "/sla/project_trackers/#{link.id}.json", headers: credentials('manager')
    end
    assert_response :not_found
  end

  test 'project context must match the assignment even for administrators' do
    link = SlaProjectTracker.find_by!(project_id: 1, tracker_id: 1)
    patch "/projects/2/sla/trackers/#{link.id}.json",
      params: {sla_project_tracker: {sla_id: 1}}, headers: credentials('admin')
    assert_response :forbidden
    assert_equal 1, link.reload.project_id
    assert_no_difference 'SlaProjectTracker.count' do
      delete "/projects/2/sla/trackers/#{link.id}.json", headers: credentials('admin')
    end
    assert_response :forbidden
  end

  test 'mixed project bulk deletion leaves all assignments intact' do
    ids = [SlaProjectTracker.find_by!(project_id: 1).id, SlaProjectTracker.find_by!(project_id: 2).id]
    assert_no_difference 'SlaProjectTracker.count' do
      delete '/sla/project_trackers.json', params: {ids: ids}, headers: credentials('manager')
    end
    assert_response :not_found
    assert_equal 2, SlaProjectTracker.where(id: ids).count
  end

  test 'manager can create update and delete assignments in the allowed project' do
    assert_difference 'SlaProjectTracker.count', 1 do
      post '/projects/1/sla/trackers.json', params: {sla_project_tracker: attributes_for(1)},
        headers: credentials('manager')
    end
    assert_response :created
    link = SlaProjectTracker.find(JSON.parse(response.body).fetch('sla_project_tracker').fetch('id'))
    patch "/projects/1/sla/trackers/#{link.id}.json",
      params: {sla_project_tracker: {sla_id: 2}}, headers: credentials('manager')
    assert_response :success
    assert_equal 2, link.reload.sla_id
    assert_difference 'SlaProjectTracker.count', -1 do
      delete "/projects/1/sla/trackers/#{link.id}.json", headers: credentials('manager')
    end
    assert_response :success
  end

  private

  def attributes_for(project_id)
    {project_id: project_id, tracker_id: 2, sla_id: 1}
  end
end
