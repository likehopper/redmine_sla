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

# File: redmine_sla/test/unit/sla_default_query_retrieval_test.rb
# Purpose:
#   RedmineSla::DefaultQueryRetrieval replaces the copies of
#   retrieve_default_query that each SLA list controller carried.
#
# Redmine SLA - Redmine's Plugin

require File.expand_path('../../application_sla_units_test_case', __FILE__)

class SlaDefaultQueryRetrievalTest < ApplicationSlaUnitsTestCase
  # The controller state the module reads: params, session, @project and
  # api_request?.
  class FakeController
    include RedmineSla::DefaultQueryRetrieval
    attr_reader :params, :session

    def initialize(params: {}, session: {}, project: nil, api: false)
      @params = ActiveSupport::HashWithIndifferentAccess.new(params)
      @session = session
      @project = project
      @api = api
    end

    def api_request?
      @api
    end

    def run(query_class, use_session = true)
      retrieve_default_query(query_class, use_session)
      params
    end
  end

  def setup
    @user = User.find(1)
    User.current = @user
    @project = Project.find(1)
    @default = SlaProjectTrackerQuery.create!(name: 'Default mappings', user: @user,
                                              visibility: Query::VISIBILITY_PUBLIC)
    @user.pref.default_issue_query = @default.id
    @user.pref.save!
  end

  def teardown
    User.current = nil
  end

  test "selects the default query when nothing is chosen" do
    assert_equal @default.id, FakeController.new(project: @project).run(SlaProjectTrackerQuery)[:query_id]
  end

  test "keeps an explicit query, explicit filters and API requests unchanged" do
    assert_equal '7', FakeController.new(params: {query_id: '7'}).run(SlaProjectTrackerQuery)[:query_id]
    assert_nil FakeController.new(params: {set_filter: '1'}).run(SlaProjectTrackerQuery)[:query_id]
    assert_nil FakeController.new(api: true).run(SlaProjectTrackerQuery)[:query_id]
  end

  test "without_default applies the filters instead of a default query" do
    params = FakeController.new(params: {without_default: '1'}).run(SlaProjectTrackerQuery)
    assert_equal 1, params[:set_filter]
    assert_nil params[:query_id]
  end

  test "keeps the session query of the same project" do
    other = SlaProjectTrackerQuery.create!(name: 'Other', user: @user, visibility: Query::VISIBILITY_PUBLIC)
    session = {sla_project_tracker_query: {id: other.id, project_id: @project.id}}
    assert_nil FakeController.new(session: session, project: @project).run(SlaProjectTrackerQuery)[:query_id]
  end

  test "ignores a session query of another project, or when the session is not used" do
    other = SlaProjectTrackerQuery.create!(name: 'Other', user: @user, visibility: Query::VISIBILITY_PUBLIC)
    session = {sla_project_tracker_query: {id: other.id, project_id: @project.id + 1}}
    assert_equal @default.id, FakeController.new(session: session, project: @project).run(SlaProjectTrackerQuery)[:query_id]

    session = {sla_project_tracker_query: {id: other.id, project_id: @project.id}}
    assert_equal @default.id,
                 FakeController.new(session: session, project: @project).run(SlaProjectTrackerQuery, false)[:query_id]
  end

  test "leaves the list unchanged for query classes without a default" do
    assert_nil FakeController.new.run(SlaLevelTermQuery)[:query_id]
    assert_nil FakeController.new(project: @project).run(SlaCacheQuery)[:query_id]
  end
end
