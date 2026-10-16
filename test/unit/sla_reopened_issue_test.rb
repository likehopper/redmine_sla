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

# File: redmine_sla/test/unit/sla_reopened_issue_test.rb
# Purpose:
#   Redmine keeps closed_on, as the last closing date, when an issue is
#   reopened. SLA spent time must keep counting until the issue is closed
#   again, in the SQL calculation and in the Explain service alike.
#
# Redmine SLA - Redmine's Plugin

require File.expand_path('../../application_sla_units_test_case', __FILE__)
require Rails.root.join('plugins/redmine_sla/db/migrate/202111112021024_count_reopened_issues_spent')

class SlaReopenedIssueTest < ApplicationSlaUnitsTestCase
  GTI = 1 # counts New
  GTR = 2 # counts New and Assigned

  test "fixture reopened and still open keeps its first closing date" do
    issue = Issue.find_by!(subject: 'Bug reopened and still open')

    assert_not issue.closed?
    assert_equal 'Resolved', issue.status.name
    assert_equal Time.utc(2021, 11, 16, 12, 0), issue.closed_on
  end

  test "spent time counts the statuses after the reopening of an open issue" do
    issue = Issue.find_by!(subject: 'Bug reopened and still open')

    # 30 + 45 min in New, 90 + 60 min in New/Assigned
    assert_equal 75, issue.get_sla_spent(GTI)
    assert_equal 150, issue.get_sla_spent(GTR)
    assert_equal false, issue.get_sla_respect(GTI)
    assert_equal false, issue.get_sla_respect(GTR)
  end

  test "spent time counts the statuses up to the last closing" do
    issue = Issue.find_by!(subject: 'Bug reopened then closed again')

    assert issue.closed?
    assert_equal Time.utc(2021, 11, 17, 15, 0), issue.closed_on
    assert_equal 30, issue.get_sla_spent(GTI)
    assert_equal 150, issue.get_sla_spent(GTR)
  end

  test "explanation of a reopened issue matches its spent time" do
    issue = Issue.find_by!(subject: 'Bug reopened and still open')
    explanation = RedmineSla::SlaExplanation.new(issue)

    assert_equal 75, explanation.spent(GTI).sum { |row| row['minutes_counted'] }
    assert_equal 150, explanation.spent(GTR).sum { |row| row['minutes_counted'] }
    # The last interval runs until now, not until the first closing.
    assert_operator explanation.spent(GTR).map { |row| row['to_status_date'] }.max, :>, 1.day.ago
  end

  test "reopening a closed issue resumes its spent time" do
    project = Project.find_by!(identifier: 'project-sla-tests-tma')
    issue = Issue.find_by!(project: project, subject: 'Bug with simple SLA')
    assert issue.closed?
    assert_equal 90, issue.get_sla_spent(GTR)
    # Spent cache last updated after the closing (12:00), before the reopening.
    SlaCacheSpent.where(issue_id: issue.id).update_all(updated_on: Time.utc(2021, 11, 3, 13, 0))

    reopen(issue, Time.utc(2021, 11, 3, 14, 0), 'Assigned')

    # Incremental update since 13:00: at least the afternoon of the
    # reopening day, in Assigned since 14:00.
    assert_operator Issue.find(issue.id).get_sla_spent(GTR), :>=, 90 + 4 * 60
  end

  test "migration purges the stale spent cache of reopened issues only" do
    # CREATE VIEW/FUNCTION commit implicitly on MySQL/MariaDB, which would
    # end the transaction isolating this test.
    skip "PostgreSQL only" unless RedmineSla::DbDialect.adapter == :postgresql

    reopened = Issue.find_by!(subject: 'Bug reopened and still open')
    closed = Issue.find_by!(subject: 'Bug reopened then closed again')
    reopened.get_sla_spent(GTR)
    closed.get_sla_spent(GTR)

    CountReopenedIssuesSpent.new.migrate(:up)

    assert_not SlaCacheSpent.where(issue_id: reopened.id).exists?
    assert SlaCacheSpent.where(issue_id: closed.id).exists?
    assert_equal 150, Issue.find(reopened.id).get_sla_spent(GTR)
  end

  private

  def reopen(issue, date, status_name)
    status = IssueStatus.find_by!(name: status_name)
    journal = Journal.new(journalized: issue, user_id: 1, notes: 'Reopened')
    journal.save!(validate: false)
    journal.update_columns(created_on: date)
    JournalDetail.create!(journal: journal, property: 'attr', prop_key: 'status_id',
                          old_value: issue.status_id.to_s, value: status.id.to_s)
    # Redmine keeps closed_on when an issue is reopened.
    issue.update_columns(status_id: status.id)
  end
end
