# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

require File.expand_path('../../application_sla_units_test_case', __FILE__)
require Rails.root.join('plugins/redmine_sla/db/migrate/202111112021028_select_sla_level_by_priority')

class SlaLevelByPriorityTest < ApplicationSlaUnitsTestCase
  test "priority-specific levels select 24x7 or business hours at and outside work hours" do
    always_on, business_hours, low, normal, = configure_priority_levels

    scenarios = [
      [low.id, Time.zone.local(2021, 12, 7, 10, 0), always_on.id, Time.zone.local(2021, 12, 7, 10, 0)],
      [normal.id, Time.zone.local(2021, 12, 7, 10, 0), business_hours.id, Time.zone.local(2021, 12, 7, 10, 0)],
      [low.id, Time.zone.local(2021, 12, 7, 22, 0), always_on.id, Time.zone.local(2021, 12, 7, 22, 0)],
      [normal.id, Time.zone.local(2021, 12, 7, 22, 0), business_hours.id, Time.zone.local(2021, 12, 8, 9, 0)]
    ]

    scenarios.each do |priority_id, created_on, expected_level_id, expected_start|
      issue = create_issue_at(created_on, priority_id)
      cache = SlaCache.find_by_issue_id(issue.id)

      assert_equal expected_level_id, cache&.sla_level_id
      assert_equal expected_start, cache&.start_date
      selected = RedmineSla::SlaExplanation.new(issue).levels.select { |row| row['selected'] }
      assert_equal [expected_level_id], selected.map { |row| row['sla_level_id'] }
    end
  end

  test "changing priority from Normal to Urgent switches calendars and recalculates spent time" do
    always_on, business_hours, _, normal, urgent = configure_priority_levels
    created_on = Time.zone.local(2021, 12, 7, 22, 0)
    issue = create_issue_at(created_on, normal.id)
    old_cache = SlaCache.find_by_issue_id(issue.id)
    assert_equal business_hours.id, old_cache&.sla_level_id
    assert_equal Time.zone.local(2021, 12, 8, 9, 0), old_cache&.start_date
    assert_not_nil issue.get_sla_spent(1)
    assert SlaCacheSpent.exists?(issue_id: issue.id)

    issue.reload.update!(priority_id: urgent.id)

    assert_not SlaCache.unscoped.exists?(issue_id: issue.id)
    assert_not SlaCacheSpent.unscoped.exists?(issue_id: issue.id)
    new_cache = SlaCache.find_by_issue_id(issue.id)
    assert_equal always_on.id, new_cache&.sla_level_id
    assert_equal created_on, new_cache&.start_date
    assert_not_nil issue.get_sla_spent(1)
    assert SlaCacheSpent.exists?(issue_id: issue.id)
  end

  test "priority change refreshes the cache and a priority without any term has no SLA" do
    issue = Issue.find(34)
    assert SlaCache.find_by_issue_id(issue.id)

    uncovered_priority = IssuePriority.find(1).dup
    uncovered_priority.name = 'Priority without SLA terms'
    uncovered_priority.position = 99
    uncovered_priority.is_default = false
    uncovered_priority.save!

    issue.update!(priority_id: uncovered_priority.id)

    assert_nil issue.get_sla_level
    assert_not SlaCache.unscoped.exists?(issue_id: issue.id)
  end

  test "custom-field priority changes select its matching level and blank values produce no cache" do
    issue = Issue.find(66)
    original_level = issue.get_sla_level
    assert_not_nil original_level.custom_field_id

    replacement = SlaLevel.create!(
      name: 'Priority-specific custom-field level',
      sla: original_level.sla,
      sla_calendar: calendar_with_schedules('custom priority schedule', (0..6).to_a, '00:00', '23:59'),
      custom_field_id: original_level.custom_field_id
    )
    SlaLevelTerm.find_by!(sla_level_id: original_level.id, sla_type_id: 1, sla_priority_id: 2).destroy!
    SlaLevelTerm.create!(sla_level: replacement, sla_type_id: 1, sla_priority_id: 2, term: 90)

    issue.custom_field_values = { original_level.custom_field_id.to_s => '2' }
    issue.save!

    assert_equal replacement.id, issue.get_sla_cache&.sla_level_id

    original_level.custom_field.update!(is_required: false)
    issue.reload
    issue.custom_field_values = { original_level.custom_field_id.to_s => '' }
    issue.save!

    assert_nil issue.get_sla_level
    assert_not SlaCache.unscoped.exists?(issue_id: issue.id)
  end

  test "migration removes only caches whose selected level lacks a priority term" do
    invalid_issue = Issue.find(4)
    invalid_cache = SlaCache.find_by_issue_id(invalid_issue.id)
    valid_cache = SlaCache.where.not(issue_id: invalid_issue.id).first
    assert invalid_cache
    assert valid_cache

    uncovered_priority = IssuePriority.find(1).dup
    uncovered_priority.name = 'Uncovered migration'
    uncovered_priority.position = 100
    uncovered_priority.is_default = false
    uncovered_priority.save!
    invalid_issue.update_column(:priority_id, uncovered_priority.id)

    SelectSlaLevelByPriority.new.delete_caches_without_priority_term

    assert_not SlaCache.unscoped.exists?(invalid_cache.id)
    assert SlaCache.unscoped.exists?(valid_cache.id)
  end

  private

  def configure_priority_levels
    always_on, business_hours = SlaLevel.where(sla_id: 4).order(:id).to_a
    always_on.sla_level_terms.destroy_all
    business_hours.sla_level_terms.destroy_all
    always_on.update!(sla_calendar: calendar_with_schedules('24x7', (0..6).to_a, '00:00', '23:59'))
    business_hours.update!(sla_calendar: calendar_with_schedules('8x5', (1..5).to_a, '09:00', '17:00'))
    low = IssuePriority.find_by!(name: 'Low')
    normal = IssuePriority.find_by!(name: 'Normal')
    urgent = IssuePriority.find_by(name: 'Urgent') ||
      IssuePriority.create!(name: 'Urgent', position: 4, position_name: 'high2',
                            active: true, is_default: false)
    SlaLevelTerm.create!(sla_level: always_on, sla_type_id: 1, sla_priority_id: low.id, term: 60)
    SlaLevelTerm.create!(sla_level: always_on, sla_type_id: 1, sla_priority_id: urgent.id, term: 30)
    SlaLevelTerm.create!(sla_level: business_hours, sla_type_id: 1, sla_priority_id: normal.id, term: 120)
    [always_on, business_hours, low, normal, urgent]
  end

  def calendar_with_schedules(name, weekdays, start_time, end_time)
    calendar = SlaCalendar.create!(name: name)
    weekdays.each do |dow|
      SlaSchedule.create!(
        sla_calendar: calendar,
        dow: dow,
        start_time: start_time,
        end_time: end_time,
        match: true
      )
    end
    calendar
  end

  def create_issue_at(created_on, priority_id)
    issue = Issue.find(34).dup
    issue.subject = "Priority selection test #{priority_id} at #{created_on}"
    issue.priority_id = priority_id
    travel_to(created_on) { issue.save! }
    issue
  end
end
