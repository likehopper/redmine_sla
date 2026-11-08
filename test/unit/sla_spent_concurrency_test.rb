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

# File: redmine_sla/test/unit/sla_spent_concurrency_test.rb
# Purpose:
#   sla_get_spent adds the minutes elapsed since its last run to the stored
#   total. Two concurrent calls for the same issue must not both add the same
#   minutes, e.g. two users displaying the same issue list, or the update_sla
#   task running while users browse.
#
# Redmine SLA - Redmine's Plugin

require File.expand_path('../../application_sla_units_test_case', __FILE__)

class SlaSpentConcurrencyTest < ApplicationSlaUnitsTestCase
  # Each thread needs its own committed view of the data: a test transaction
  # would hide one connection's writes from the other.
  self.use_transactional_tests = false

  GTR = 2 # counts New and Assigned
  # Lets the second call reach its read of sla_cache_spents while the first
  # call's transaction is still open.
  OVERLAP_SECONDS = 1

  def setup
    project = Project.find_by!(identifier: 'project-sla-tests-tma')
    @issue = Issue.find_by!(project: project, subject: 'Bug with simple SLA')
    # Closed issue: the calculation window ends at closed_on, so the expected
    # total does not depend on the time the test runs.
    assert @issue.closed?
    SlaCacheSpent.where(issue_id: @issue.id).delete_all
  end

  def teardown
    # Leave no extra total behind for the tests sharing this database:
    # the spent cache is recalculated on demand.
    SlaCacheSpent.where(issue_id: @issue.id).delete_all if @issue
  end

  test "two concurrent calculations count the spent time once" do
    first_call_done = Queue.new
    first_call_released = Queue.new

    first = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        ActiveRecord::Base.transaction do
          SlaCacheSpent.find_by_issue_and_type_id(@issue, GTR)
          first_call_done << true
          # Keep the transaction, and its row locks, open while the second
          # call runs.
          first_call_released.pop
        end
      end
    end

    second = Thread.new do
      first_call_done.pop
      ActiveRecord::Base.connection_pool.with_connection do
        SlaCacheSpent.find_by_issue_and_type_id(@issue, GTR)
      end
    end

    ActiveSupport::Dependencies.interlock.permit_concurrent_loads do
      sleep OVERLAP_SECONDS
      first_call_released << true
      [first, second].each(&:join)
    end

    assert_equal 90, SlaCacheSpent.find_by!(issue_id: @issue.id, sla_type_id: GTR).spent
  end
end
