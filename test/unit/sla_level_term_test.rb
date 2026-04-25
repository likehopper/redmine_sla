# frozen_string_literal: true

# File: redmine_sla/test/unit/sla_level_term_test.rb
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

class SlaLevelTermTest < ApplicationSlaUnitsTestCase

  # Fixture: (sla_level_id: 1, sla_type_id: 1, sla_priority_id: 1, term: 120) already exists.
  # Use sla_priority_id: 999 to avoid conflicts when creating new records.

  def valid_term(overrides = {})
    SlaLevelTerm.new({
      sla_level_id:    1,
      sla_type_id:     1,
      sla_priority_id: 999,
      term:            60
    }.merge(overrides))
  end

  # --- Passing cases ---

  test "valid term with all required fields" do
    assert valid_term.valid?
  end

  test "term equal to zero is valid" do
    assert valid_term(term: 0).valid?
  end

  # --- Presence validations ---

  test "should not save without sla_level" do
    t = valid_term(sla_level_id: nil)
    assert_not t.valid?
    assert t.errors[:sla_level].present?
  end

  test "should not save without sla_type" do
    t = valid_term(sla_type_id: nil)
    assert_not t.valid?
    assert t.errors[:sla_type].present?
  end

  test "should not save without sla_priority_id" do
    t = valid_term(sla_priority_id: nil)
    assert_not t.valid?
    assert t.errors[:sla_priority_id].present?
  end

  test "should not save without term" do
    t = valid_term(term: nil)
    assert_not t.valid?
    assert t.errors[:term].present?
  end

  # --- Numericality ---

  test "should not save with negative term" do
    t = valid_term(term: -1)
    assert_not t.valid?
    assert t.errors[:term].present?
  end

  # --- Uniqueness: (sla_level, sla_type, sla_priority_id) must be unique ---
  # The fixture already has (1, 1, 1); creating another with those values must fail.

  test "should reject duplicate (sla_level, sla_type, sla_priority_id)" do
    duplicate = valid_term(sla_priority_id: 1)
    assert_not duplicate.valid?, "Duplicate (level, type, priority) should be rejected"
    assert duplicate.errors[:sla_level].present?
  end

  test "same level+type with a different priority_id is valid" do
    assert valid_term(sla_priority_id: 999).valid?
  end

end