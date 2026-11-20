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

# File: redmine_sla/test/unit/sla_query_stable_order_test.rb
# Purpose:
#   Paginated SLA lists must end their ORDER BY with a unique column: rows with
#   equal sort values are otherwise ordered differently by each database, and a
#   row can appear on two pages or on none.

require File.expand_path('../../application_sla_units_test_case', __FILE__)

class SlaQueryStableOrderTest < ApplicationSlaUnitsTestCase
  LIST_QUERIES = {
    SlaQuery => :slas,
    SlaTypeQuery => :sla_types,
    SlaStatusQuery => :sla_statuses,
    SlaHolidayQuery => :sla_holidays,
    SlaCalendarQuery => :sla_calendars,
    SlaCalendarHolidayQuery => :sla_calendar_holidays,
    SlaScheduleQuery => :sla_schedules,
    SlaLevelQuery => :sla_levels,
    SlaLevelTermQuery => :sla_level_terms,
    SlaProjectTrackerQuery => :sla_project_trackers
  }.freeze

  setup do
    User.current = User.find(1)
  end

  teardown do
    User.current = nil
  end

  LIST_QUERIES.each do |query_class, list_method|
    test "#{query_class.name} ends its order with the row id" do
      table = query_class.queried_class.table_name
      query = query_class.new(name: '_')
      # Sort on a column other than id, as a user can, so the tie-breaker is the only id criterion.
      column = query.available_columns.find { |item| item.sortable && item.name != :id }
      refute_nil column, "#{query_class.name} has no sortable column besides id"
      query.sort_criteria = [[column.name.to_s, 'asc']]
      statements = []
      callback = ->(*, payload) { statements << payload[:sql] if payload[:sql] =~ /\ASELECT/i }
      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
        query.send(list_method, limit: 5, offset: 0)
      end

      ordered = statements.grep(/ORDER BY/i).find { |sql| sql.include?(table) }
      refute_nil ordered, "no ordered SELECT on #{table}"
      assert_match(/ORDER BY .*#{Regexp.escape(table)}\.id ASC\s*(LIMIT|OFFSET|\z)/im, ordered)
    end
  end

  test "calendar holiday pages neither repeat nor skip rows sharing a date" do
    query = SlaCalendarHolidayQuery.new(name: '_')
    all_rows = query.sla_calendar_holidays
    dates = all_rows.map { |row| row.sla_holiday.date }
    assert_operator dates.size, :>, dates.uniq.size, 'fixtures need calendar holidays sharing a date'

    expected = all_rows.sort_by { |row| [-row.sla_holiday.date.jd, row.sla_calendar.name, row.id] }.map(&:id)
    assert_equal expected, all_rows.map(&:id)

    page_size = 3
    paged = (0...all_rows.size).step(page_size).flat_map do |offset|
      query.sla_calendar_holidays(limit: page_size, offset: offset).map(&:id)
    end
    assert_equal expected, paged
  end
end
