# frozen_string_literal: true

# File: redmine_sla/test/unit/sla_schedule_test.rb
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

class SlaScheduleTest < ApplicationSlaUnitsTestCase

  setup do
    @calendar = SlaCalendar.find(1)
  end

  # Build a valid schedule using dow=0 (sunday) on calendar 1.
  # Calendar 1 has no fixtures for dow=0, so there are no pre-existing conflicts.
  def valid_schedule(overrides = {})
    SlaSchedule.new({
      sla_calendar_id: @calendar.id,
      dow: 0,
      start_time: "10:00:00",
      end_time: "12:00:00",
      match: true
    }.merge(overrides))
  end

  # --- Passing cases ---

  test "valid schedule with all required fields" do
    assert valid_schedule.valid?, "A complete schedule should be valid"
  end

  test "two schedules on same cal+dow with distinct start AND end are both valid" do
    first  = valid_schedule(start_time: "09:00:00", end_time: "11:00:00")
    second = valid_schedule(start_time: "13:00:00", end_time: "17:00:00")
    assert first.save, "First schedule should save"
    assert second.valid?, "Second schedule with distinct start and end should be valid"
  end

  test "same times on a different calendar are valid" do
    assert valid_schedule.save, "First schedule should save"
    other = valid_schedule(sla_calendar_id: SlaCalendar.find(2).id)
    assert other.valid?, "Same times on a different calendar should be valid"
  end

  # --- Presence validations ---

  test "should not save without sla_calendar" do
    s = valid_schedule(sla_calendar_id: nil)
    assert_not s.valid?, "Schedule without calendar should be invalid"
    assert s.errors[:sla_calendar].present?
  end

  test "should not save without dow" do
    s = valid_schedule(dow: nil)
    assert_not s.valid?, "Schedule without dow should be invalid"
    assert s.errors[:dow].present?
  end

  test "should not save without start_time" do
    s = valid_schedule(start_time: nil)
    assert_not s.valid?, "Schedule without start_time should be invalid"
    assert s.errors[:start_time].present?
  end

  test "should not save without end_time" do
    s = valid_schedule(end_time: nil)
    assert_not s.valid?, "Schedule without end_time should be invalid"
    assert s.errors[:end_time].present?
  end

  test "should not save with match nil" do
    s = valid_schedule(match: nil)
    assert_not s.valid?, "Schedule with nil match should be invalid"
    assert s.errors[:match].present?
  end

  # --- Uniqueness: constraint 1 - (sla_calendar_id, dow, start_time) ---

  test "should reject duplicate start_time on same calendar+dow" do
    first = valid_schedule(start_time: "09:00:00", end_time: "11:00:00")
    assert first.save, "First schedule should save"
    duplicate = valid_schedule(start_time: "09:00:00", end_time: "17:00:00")
    assert_not duplicate.valid?, "Same start_time on same cal+dow should be rejected"
    assert duplicate.errors[:sla_calendar_id].present?
  end

  # --- Uniqueness: constraint 2 - (sla_calendar_id, dow, end_time) ---
  # This constraint was fixed: the old scope [:dow, :start_time, :end_time] was
  # redundant with constraint 1. The new scope [:dow, :end_time] independently
  # rejects two schedules that share the same end time on the same day.

  # before_save normalises end_time to HH:MM:59, so we must use the already-normalised
  # form ("12:00:59") for both records. Otherwise the saved value ("12:00:59") and the
  # in-memory value ("12:00:00") differ and the uniqueness query misses the conflict.
  test "should reject duplicate end_time on same calendar+dow even with different start_time" do
    first = valid_schedule(start_time: "09:00:00", end_time: "12:00:59")
    assert first.save, "First schedule should save"
    duplicate = valid_schedule(start_time: "10:00:00", end_time: "12:00:59")
    assert_not duplicate.valid?, "Same end_time on same cal+dow should be rejected (fixed constraint)"
    assert duplicate.errors[:sla_calendar_id].present?
  end

  # --- Inconsistency: start must be strictly before end ---

  test "should not save when start_time is after end_time" do
    s = valid_schedule(start_time: "14:00:00", end_time: "10:00:00")
    assert_not s.valid?, "start_time after end_time should be invalid"
    assert s.errors[:base].present?
  end

  test "should not save when start_time equals end_time" do
    s = valid_schedule(start_time: "10:00:00", end_time: "10:00:00")
    assert_not s.valid?, "start_time equal to end_time should be invalid"
    assert s.errors[:base].present?
  end

end