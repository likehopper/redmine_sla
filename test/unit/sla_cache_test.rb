# frozen_string_literal: true

# File: redmine_sla/test/unit/sla_cache_test.rb
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

class SlaCacheTest < ApplicationSlaUnitsTestCase

  test "sla_caches are present in the test database" do
    assert_not SlaCache.count.zero?
  end

  # --- Uniqueness: one SlaCache per issue ---

  test "should reject a second SlaCache for the same issue" do
    existing = SlaCache.first
    duplicate = SlaCache.new(issue_id: existing.issue_id, sla_level_id: existing.sla_level_id,
                             project_id: existing.project_id)
    assert_not duplicate.valid?, "Two SlaCache for the same issue should be rejected"
    assert duplicate.errors[:issue].present? || duplicate.errors[:issue_id].present?
  end

  # --- Finder ---

  test "find_by_issue_id returns the cache for a known issue" do
    existing = SlaCache.first
    found = SlaCache.find_by_issue_id(existing.issue_id)
    assert_not_nil found
    assert_equal existing.issue_id, found.issue_id
  end

  test "find_by_issue_id returns nil for an unknown issue" do
    assert_nil SlaCache.find_by_issue_id(999_999)
  end

  # --- Visibility ---
  # visible? calls issue.visible? without a user argument, so it falls back to
  # User.current. We must set User.current to a user that has :view_issues on
  # the project, otherwise issue.visible? returns false regardless of the user
  # passed to visible?. User 2 (manager) has both :view_sla and :manage_sla.

  test "visible? returns true for a user with :view_sla on the project" do
    cache = SlaCache.where(project: 1).order(:id).first
    manager = User.find(2)
    User.current = manager
    assert cache.visible?(manager), "Manager with :view_sla should be able to see a SlaCache"
  ensure
    User.current = nil
  end

  test "deletable? returns true for a user with :manage_sla on the project" do
    cache = SlaCache.where(project: 1).order(:id).first
    manager = User.find(2)
    User.current = manager
    assert cache.deletable?(manager), "Manager with :manage_sla should be able to delete a SlaCache"
  ensure
    User.current = nil
  end

end