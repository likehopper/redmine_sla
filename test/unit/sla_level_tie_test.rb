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

# File: redmine_sla/test/unit/sla_level_tie_test.rb
# Purpose:
#   Two levels of one SLA whose calendars open at the same minute tie in
#   sla_get_level. The level with the lowest id must win, on every refresh.
#
# Redmine SLA - Redmine's Plugin

require File.expand_path('../../application_sla_units_test_case', __FILE__)

class SlaLevelTieTest < ApplicationSlaUnitsTestCase
  test "levels opening at the same minute resolve to the lowest level id on every refresh" do
    project = Project.find_by!(identifier: 'project-sla-tests-tma')
    issue = Issue.find_by!(project: project, subject: 'Bug with simple SLA')
    level = SlaLevel.find(SlaCache.find_by_issue_id(issue.id).sla_level_id)
    twin = SlaLevel.create!(name: 'Tie level', sla: level.sla, sla_calendar: copy_calendar(level.sla_calendar),
                            custom_field_id: level.custom_field_id)
    level.sla_level_terms.each do |term|
      SlaLevelTerm.create!(sla_level: twin, sla_type_id: term.sla_type_id,
                           sla_priority_id: term.sla_priority_id, term: term.term)
    end
    expected = [level.id, twin.id].min

    5.times do
      ActiveRecord::Base.connection.execute(
        ActiveRecord::Base.sanitize_sql(['SELECT sla_get_level(?, true)', issue.id])
      )
      assert_equal expected, SlaCache.find_by!(issue_id: issue.id).sla_level_id
    end

    selected_rows = RedmineSla::SlaExplanation.new(issue).levels.select { |row| row['selected'] }
    assert_equal [expected], selected_rows.map { |row| row['sla_level_id'] }
  end

  private

  # Same schedules and holidays, so both calendars open at the same minute.
  def copy_calendar(calendar)
    copy = SlaCalendar.create!(name: "#{calendar.name} tie")
    calendar.sla_schedules.each do |schedule|
      copy.sla_schedules.create!(dow: schedule.dow, start_time: schedule.start_time,
                                 end_time: schedule.end_time, match: schedule.match)
    end
    SlaCalendarHoliday.where(sla_calendar_id: calendar.id).each do |holiday|
      SlaCalendarHoliday.create!(sla_calendar: copy, sla_holiday_id: holiday.sla_holiday_id, match: holiday.match)
    end
    copy
  end
end
