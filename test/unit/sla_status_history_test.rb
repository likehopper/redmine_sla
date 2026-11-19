# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

require File.expand_path('../../application_sla_units_test_case', __FILE__)

class SlaStatusHistoryTest < ApplicationSlaUnitsTestCase
  test 'unrelated journal entries do not change the initial counted status' do
    issue = Issue.find_by!(project_id: 1, subject: 'Bug with simple SLA')
    # Notes and non-status details precede and follow the real changes.
    50.times do |offset|
      journal_id = Journal.maximum(:id) + 1
      Journal.insert_all!([{id: journal_id, journalized_type: 'Issue',
        journalized_id: issue.id, user_id: 1, notes: 'Unrelated note',
        created_on: issue.created_on + offset.minutes}])
      JournalDetail.insert_all!([{journal_id: journal_id, property: 'attr',
        prop_key: 'subject', old_value: 'Before', value: 'After'}])
    end
    SlaCacheSpent.where(issue_id: issue.id).delete_all

    assert_equal 30, SlaCacheSpent.find_by_issue_and_type_id(issue, 1).spent
    assert_equal 90, SlaCacheSpent.find_by_issue_and_type_id(issue, 2).spent
  end

  test 'an issue without status changes falls back to its current status' do
    issue = Issue.find_by!(project_id: 1, subject: 'Bug with simple SLA')
    JournalDetail.where(journal_id: Journal.where(journalized_id: issue.id,
      journalized_type: 'Issue').select(:id)).delete_all
    # The closed status now counts: the whole two-hour lifetime must count,
    # whether the issue has comment-only journals or no journals at all.
    SlaStatus.create!(sla_type_id: 2, status_id: issue.status_id)
    SlaCacheSpent.where(issue_id: issue.id).delete_all
    assert_equal 120, SlaCacheSpent.find_by_issue_and_type_id(issue, 2).spent

    Journal.where(journalized_id: issue.id, journalized_type: 'Issue').delete_all
    SlaCacheSpent.where(issue_id: issue.id).delete_all
    assert_equal 120, SlaCacheSpent.find_by_issue_and_type_id(issue, 2).spent
  end

  test 'history bounds use the configured timezone' do
    issue = Issue.find_by!(project_id: 1, subject: 'Bug with simple SLA')
    JournalDetail.where(journal_id: Journal.where(journalized_id: issue.id,
      journalized_type: 'Issue').select(:id)).delete_all
    SlaStatus.create!(sla_type_id: 2, status_id: issue.status_id)
    SlaCache.where(issue_id: issue.id).delete_all

    # with_settings also restores Redmine's in-memory settings cache, which a
    # transaction rollback leaves untouched.
    with_settings plugin_redmine_sla: Setting.plugin_redmine_sla.merge('sla_time_zone' => 'America/New_York') do
      # 10:00-12:00 UTC is before this calendar opens at 09:00 in New York.
      assert_equal 0, SlaCacheSpent.find_by_issue_and_type_id(issue, 2).spent
    end
  end

end
