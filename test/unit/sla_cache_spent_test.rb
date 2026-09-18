# frozen_string_literal: true

# File: redmine_sla/test/unit/sla_cache_spent_test.rb
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

class SlaCacheSpentTest < ApplicationSlaUnitsTestCase

  test "sla_cache_spents are present in the test database" do
    assert_not SlaCacheSpent.count.zero?
  end

  test "global spent purge keeps cache rows" do
    cache_ids = SlaCache.unscoped.order(:id).pluck(:id)
    assert_not_empty cache_ids
    assert SlaCacheSpent.unscoped.exists?

    if RedmineSla::DbDialect.adapter == :mysql
      connection = ActiveRecord::Base.connection
      original_checks = connection.select_value("SELECT @@SESSION.foreign_key_checks").to_i
      connection.execute("SET FOREIGN_KEY_CHECKS = 0")
    end

    begin
      SlaCacheSpent.purge(nil)
      assert_equal 0, connection.select_value("SELECT @@SESSION.foreign_key_checks").to_i if connection
    ensure
      connection.execute("SET FOREIGN_KEY_CHECKS = #{original_checks}") if connection
    end

    assert_not SlaCacheSpent.unscoped.exists?
    assert_equal cache_ids, SlaCache.unscoped.order(:id).pluck(:id)
  end

  # --- Finder ---

  test "find_by_issue_and_type_id returns a record for a known issue+type" do
    existing = SlaCacheSpent.first
    found = SlaCacheSpent.find_by_issue_and_type_id(existing.issue, existing.sla_type_id)
    assert_not_nil found
    assert_equal existing.issue_id,   found.issue_id
    assert_equal existing.sla_type_id, found.sla_type_id
  end

  test "find_by_issue_and_type_id returns nil for an unknown issue" do
    fake_issue = Issue.new
    fake_issue.id = 999_999
    assert_nil SlaCacheSpent.find_by_issue_and_type_id(fake_issue, 1)
  end

  # --- Visibility ---
  # visible? calls issue.visible? without a user argument (uses User.current).
  # User.current must be set to avoid the anonymous fallback returning false.

  test "visible? returns true for a user with :view_sla on the project" do
    spent = SlaCacheSpent.where(project: 1).order(:id).first
    manager = User.find(2)
    User.current = manager
    assert spent.visible?(manager), "Manager with :view_sla should be able to see a SlaCacheSpent"
  ensure
    User.current = nil
  end

end
