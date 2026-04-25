# frozen_string_literal: true

# File: redmine_sla/test/unit/sla_project_tracker_test.rb
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

class SlaProjectTrackerTest < ApplicationSlaUnitsTestCase

  # Fixture: (project_id: 1, tracker_id: 1, sla_id: 1) already exists.
  # Validation tests use .valid? only — no save — to avoid the after_save
  # callback that triggers SlaCache refresh on the full data set.

  # --- Passing cases ---

  test "valid project tracker with project, tracker and sla" do
    pt = SlaProjectTracker.new(project_id: 1, tracker_id: 2, sla_id: 1)
    assert pt.valid?
  end

  # --- Presence validations ---

  test "should not be valid without project" do
    pt = SlaProjectTracker.new(tracker_id: 1, sla_id: 1)
    assert_not pt.valid?
    assert pt.errors[:project].present?
  end

  test "should not be valid without tracker" do
    pt = SlaProjectTracker.new(project_id: 1, sla_id: 1)
    assert_not pt.valid?
    assert pt.errors[:tracker].present?
  end

  test "should not be valid without sla" do
    pt = SlaProjectTracker.new(project_id: 1, tracker_id: 1)
    assert_not pt.valid?
    assert pt.errors[:sla].present?
  end

  # --- Uniqueness: (project, tracker) must be unique ---
  # The fixture already has (project_id: 1, tracker_id: 1).
  # Querying .valid? triggers the uniqueness check without any DB write.

  test "should reject duplicate (project, tracker) combination" do
    duplicate = SlaProjectTracker.new(project_id: 1, tracker_id: 1, sla_id: 1)
    assert_not duplicate.valid?, "Duplicate (project, tracker) should be rejected"
    assert duplicate.errors[:tracker].present?
  end

  test "same project with a different tracker is valid" do
    assert SlaProjectTracker.new(project_id: 1, tracker_id: 2, sla_id: 1).valid?
  end

  test "same tracker on a different project is valid" do
    assert SlaProjectTracker.new(project_id: 2, tracker_id: 1, sla_id: 1).valid?
  end

end