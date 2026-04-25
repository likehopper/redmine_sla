# frozen_string_literal: true

# File: redmine_sla/test/unit/sla_status_test.rb
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

class SlaStatusTest < ApplicationSlaUnitsTestCase

  # Fixture data: sla_type_id 1 (GTI) + status_id 1 (New) already exists.
  def valid_status(overrides = {})
    SlaStatus.new({ sla_type_id: 1, status_id: 2 }.merge(overrides))
  end

  # --- Passing cases ---

  test "valid status with sla_type and status" do
    assert valid_status.valid?
  end

  # --- Presence validations ---

  test "should not save without sla_type" do
    s = valid_status(sla_type_id: nil)
    assert_not s.valid?
    assert s.errors[:sla_type].present?
  end

  test "should not save without status" do
    s = valid_status(status_id: nil)
    assert_not s.valid?
    assert s.errors[:status].present?
  end

  # --- Uniqueness: (sla_type_id, status_id) must be unique ---
  # Fixture already has (sla_type_id: 1, status_id: 1); trying to create it again
  # should fail without touching the DB write path.

  test "should reject duplicate sla_type+status combination" do
    duplicate = SlaStatus.new(sla_type_id: 1, status_id: 1)
    assert_not duplicate.valid?, "Duplicate (sla_type, status) should be rejected"
    assert duplicate.errors[:sla_type_id].present?
  end

  test "same sla_type with a different status is valid" do
    assert valid_status(sla_type_id: 1, status_id: 2).valid?  # (1,2) not in fixtures
  end

  test "same status with a different sla_type is valid" do
    # (2,3) is not in fixtures — status 3 (Resolved) exists in Redmine's default IssueStatus set.
    assert valid_status(sla_type_id: 2, status_id: 3).valid?
  end

end