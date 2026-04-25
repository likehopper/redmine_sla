# frozen_string_literal: true

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

class SlaTypeTest < ApplicationSlaUnitsTestCase

  # Fixtures: "GTI" (id 1) and "GTR" (id 2) already exist.

  # --- Passing cases ---

  test "valid sla_type with a unique name" do
    assert SlaType.new(name: "NEW_TYPE_TEST").valid?
  end

  test "to_s returns the name" do
    assert_equal "GTI", SlaType.find(1).to_s
  end

  # --- Presence validation ---

  test "should not save without name" do
    t = SlaType.new
    assert_not t.valid?
    assert t.errors[:name].present?
  end

  # --- Uniqueness: case-insensitive ---

  test "should reject an exact duplicate name" do
    t = SlaType.new(name: "GTI")
    assert_not t.valid?, "Duplicate name should be rejected"
    assert t.errors[:name].present?
  end

  test "should reject the same name in different case" do
    t = SlaType.new(name: "gti")
    assert_not t.valid?, "Case-insensitive duplicate should be rejected"
    assert t.errors[:name].present?
  end

  test "a distinct name is valid" do
    assert SlaType.new(name: "GTR_PREMIUM").valid?
  end

end