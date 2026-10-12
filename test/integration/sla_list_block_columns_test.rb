# frozen_string_literal: true
# File: redmine_sla/test/integration/sla_list_block_columns_test.rb
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

# Render the actual lists with two block columns, including lists that do not
# currently offer one. Assert the HTML structure rather than ERB source syntax.
class SlaListBlockColumnsTest < ApplicationSlaIntegrationTestCase
  {
    'slas' => SlaQuery, 'calendars' => SlaCalendarQuery,
    'levels' => SlaLevelQuery, 'holidays' => SlaHolidayQuery,
    'schedules' => SlaScheduleQuery, 'statuses' => SlaStatusQuery,
    'level_terms' => SlaLevelTermQuery, 'calendar_holidays' => SlaCalendarHolidayQuery,
    'project_trackers' => SlaProjectTrackerQuery, 'caches' => SlaCacheQuery,
    'cache_spents' => SlaCacheSpentQuery
  }.each do |resource, query_class|
    test "#{resource} list renders multiple block columns spanning the full row" do
      User.current = User.find(1)
      if %w[caches cache_spents].include?(resource)
        SlaCache.find_by_issue_id(7)
        SlaCacheSpent.find_by_issue_and_type_id(Issue.find(7), 1)
      end
      log_user('admin', 'admin')
      # IDs are available on every entity. Duplicate block columns exercise the
      # caption branch without adding fictitious attributes to the models.
      query_class.any_instance.stubs(:block_columns).returns([
        QueryColumn.new(:id, :inline => false), QueryColumn.new(:id, :inline => false)
      ])
      parameters = {:set_filter => 1, :c => ['id']}
      if %w[caches cache_spents].include?(resource)
        parameters.merge!(:f => ['issue.status_id'], :op => {'issue.status_id' => '*'})
      end
      get "/sla/#{resource}", :params => parameters
      assert_response :success
      document = Nokogiri::HTML(response.body)
      entity_row = document.at_css('tr.entity')
      assert entity_row, "#{resource} should contain a fixture row"
      first_block_row = entity_row.next_element
      second_block_row = first_block_row.next_element
      [first_block_row, second_block_row].each do |block_row|
        cell = block_row.at_css('td')
        assert_equal entity_row.css('td').size, cell['colspan'].to_i, resource
        assert cell.at_css('span'), "#{resource} should show captions for multiple block columns"
        assert_includes cell.text, entity_row['id'][/\d+\z/], "#{resource} should render the entity ID"
      end
    end
  end

  test "SLA type list keeps one reorderable row per type" do
    log_user('admin', 'admin')
    assert_empty SlaTypeQuery.new.available_block_columns
    get '/sla/types'
    assert_response :success
    assert_select 'table.sla_types tbody tr', :count => SlaType.count
  end
end
