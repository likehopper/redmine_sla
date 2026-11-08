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

# File: redmine_sla/test/unit/sla_inactive_priority_test.rb
# Purpose:
#   Redmine keeps a deactivated priority on the issues that already use it,
#   and the SQL respect filters still match those issues. The displayed SLA
#   priority and contractual term must resolve them as well.
#
# Redmine SLA - Redmine's Plugin

require File.expand_path('../../application_sla_units_test_case', __FILE__)

class SlaInactivePriorityTest < ApplicationSlaUnitsTestCase
  test "an inactive issue priority still resolves the SLA priority and term" do
    issue, sla_type_id = issue_with_term { |cache| cache.sla_level.custom_field_id.nil? }
    IssuePriority.find(issue.priority_id).update_column(:active, false)

    assert_resolved issue, sla_type_id
  end

  test "an inactive custom field priority still resolves the SLA priority and term" do
    issue, sla_type_id = issue_with_term { |cache| cache.sla_level.custom_field_id.present? }
    custom_field_id = issue.get_sla_level[:custom_field_id]
    CustomFieldEnumeration.find(issue.custom_field_value(custom_field_id)).update_column(:active, false)

    assert_resolved issue, sla_type_id
  end

  private

  # First cached issue matching the block that has a contractual term.
  def issue_with_term
    SlaCache.order(:issue_id).each do |cache|
      next unless yield(cache)

      issue = Issue.find(cache.issue_id)
      SlaLevelTerm.where(sla_level_id: cache.sla_level_id).distinct.pluck(:sla_type_id).each do |sla_type_id|
        return [issue, sla_type_id] if SlaLevelTerm.find_by_issue_and_type_id(issue, sla_type_id)
      end
    end
    flunk "no cached issue with a contractual term in the fixtures"
  end

  def assert_resolved(issue, sla_type_id)
    issue = Issue.find(issue.id)
    assert_not_nil SlaPriority.create_by_issue(issue), "SLA priority not resolved"
    assert_not_nil SlaLevelTerm.find_by_issue_and_type_id(issue, sla_type_id), "contractual term not resolved"
  end
end
