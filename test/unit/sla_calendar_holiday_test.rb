# frozen_string_literal: true

# File: redmine_sla/test/unit/sla_calendar_holiday_test.rb
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

require File.expand_path('../../application_sla_units_test_case', __FILE__)

class SlaCalendarHolidayTest < ApplicationSlaUnitsTestCase

  setup do
    @calendar = SlaCalendar.find(1)
    # Create a holiday in-transaction to use across tests.
    @holiday = SlaHoliday.create!(name: "Test Holiday CH", date: Date.new(2099, 7, 14))
  end

  def valid_calendar_holiday(overrides = {})
    SlaCalendarHoliday.new({
      sla_calendar_id: @calendar.id,
      sla_holiday_id:  @holiday.id,
      match: true
    }.merge(overrides))
  end

  # --- Passing cases ---

  test "valid calendar holiday with calendar, holiday and match" do
    assert valid_calendar_holiday.valid?
  end

  # --- Presence validations ---

  test "should not save without sla_calendar" do
    ch = valid_calendar_holiday(sla_calendar_id: nil)
    assert_not ch.valid?
    assert ch.errors[:sla_calendar].present?
  end

  test "should not save without sla_holiday" do
    ch = valid_calendar_holiday(sla_holiday_id: nil)
    assert_not ch.valid?
    assert ch.errors[:sla_holiday].present?
  end

  test "should not save with match nil" do
    ch = valid_calendar_holiday(match: nil)
    assert_not ch.valid?
    assert ch.errors[:match].present?
  end

  # --- Uniqueness: (calendar, holiday) pair must be unique ---

  test "should reject a duplicate calendar+holiday pair" do
    assert valid_calendar_holiday.save, "First calendar holiday should save"
    duplicate = valid_calendar_holiday
    assert_not duplicate.valid?, "Same calendar+holiday pair should be rejected"
    assert duplicate.errors[:sla_calendar].present?
  end

  test "same holiday on a different calendar is valid" do
    assert valid_calendar_holiday(sla_calendar_id: SlaCalendar.find(1).id).save
    assert valid_calendar_holiday(sla_calendar_id: SlaCalendar.find(2).id).valid?,
      "Same holiday on a different calendar should be valid"
  end

end