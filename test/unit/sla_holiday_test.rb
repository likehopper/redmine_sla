# frozen_string_literal: true

# File: redmine_sla/test/unit/sla_holiday_test.rb
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

class SlaHolidayTest < ApplicationSlaUnitsTestCase

  # Date far in the future — no fixture should already use it.
  TEST_DATE = Date.new(2099, 6, 15)

  def valid_holiday(overrides = {})
    SlaHoliday.new({ name: "Test Holiday", date: TEST_DATE }.merge(overrides))
  end

  # --- Passing cases ---

  test "valid holiday with name and date" do
    assert valid_holiday.valid?
  end

  test "to_s returns the holiday name" do
    assert_equal "Bastille Day", valid_holiday(name: "Bastille Day").to_s
  end

  # --- Presence validations ---

  test "should not save without name" do
    h = valid_holiday(name: nil)
    assert_not h.valid?
    assert h.errors[:name].present?
  end

  test "should not save without date" do
    h = valid_holiday(date: nil)
    assert_not h.valid?
    assert h.errors[:date].present?
  end

  # --- Uniqueness: each date must be unique ---

  test "should reject a duplicate date" do
    assert valid_holiday(name: "First").save, "First holiday should save"
    duplicate = valid_holiday(name: "Second")
    assert_not duplicate.valid?, "Two holidays on the same date should be rejected"
    assert duplicate.errors[:date].present?
  end

  test "same name on different dates is valid" do
    assert valid_holiday(name: "Recurring", date: TEST_DATE).save
    assert valid_holiday(name: "Recurring", date: TEST_DATE + 1).valid?,
      "Same name on a different date should be valid"
  end

end