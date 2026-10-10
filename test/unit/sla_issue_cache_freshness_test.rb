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

# File: redmine_sla/test/unit/sla_issue_cache_freshness_test.rb
# Purpose:
#   Protect SLA cache freshness across issue changes.
#
# Redmine SLA - Redmine's Plugin

require File.expand_path('../../application_sla_units_test_case', __FILE__)

class SlaIssueCacheFreshnessTest < ApplicationSlaUnitsTestCase
  test "saving a priority change refreshes memoized contractual terms" do
    issue = Issue.find(4)
    assert_equal 1680, issue.get_sla_term(1)

    issue.update!(priority_id: 2)

    assert_equal 840, Issue.find(issue.id).get_sla_term(1)
    assert_equal 840, issue.get_sla_term(1)
  end

  test "reloading an issue refreshes memoized contractual terms" do
    issue = Issue.find(4)
    assert_equal 1680, issue.get_sla_term(1)
    Issue.find(issue.id).update!(priority_id: 2)

    issue.reload

    assert_equal 840, issue.get_sla_term(1)
  end

  test "saving a tracker change refreshes a memoized SLA level" do
    issue = Issue.find(4)
    assert_not_nil issue.get_sla_level
    issue.update!(tracker_id: 1)

    assert_equal Issue.find(issue.id).get_sla_level&.id, issue.get_sla_level&.id
    assert_equal Issue.find(issue.id).get_sla_term(1), issue.get_sla_term(1)
  end

  test "saving a project change refreshes memoized cache and spent time" do
    issue = Issue.find(4)
    issue.get_sla_cache
    issue.get_sla_term(1)
    issue.get_sla_spent(1)

    issue.update!(project_id: 4)

    fresh_issue = Issue.find(issue.id)
    assert_equal 4, issue.get_sla_cache.project_id
    assert_equal fresh_issue.get_sla_level.id, issue.get_sla_level.id
    assert_nil fresh_issue.get_sla_term(1)
    assert_nil issue.get_sla_term(1)
    assert_nil fresh_issue.get_sla_spent(1)
    assert_nil issue.get_sla_spent(1)
  end

  test "saving a custom field change refreshes memoized contractual terms" do
    issue = Issue.find(66)
    initial_term = issue.get_sla_term(1)
    assert_not_nil initial_term
    level = issue.get_sla_level
    alternative = level.sla_level_terms.where(sla_type_id: 1).detect do |term|
      term.term != initial_term
    end
    assert_not_nil alternative

    issue.custom_field_values = {level.custom_field_id.to_s => alternative.sla_priority_id.to_s}
    issue.save!

    assert_equal alternative.term, Issue.find(issue.id).get_sla_term(1)
    assert_equal alternative.term, issue.get_sla_term(1)
  end
end
