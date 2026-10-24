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

# File: redmine_sla/test/unit/sla_cache_invalidation_test.rb
# Purpose:
#   Verifies targeted cache invalidation for every SLA configuration model.
#
# Redmine SLA - Redmine's Plugin

require File.expand_path('../../application_sla_units_test_case', __FILE__)

class SlaCacheInvalidationTest < ApplicationSlaUnitsTestCase
  test "calendar update invalidates caches of all competing levels" do
    calendar = calendar_with_cached_level

    assert_only_levels_invalidated(level_ids_for(calendar)) do
      calendar.update!(name: "#{calendar.name} updated")
    end
  end

  test "schedule update invalidates caches of all competing levels" do
    schedule = SlaSchedule.unscoped.detect { |record| level_ids_for(record.sla_calendar).any? }

    assert_only_levels_invalidated(level_ids_for(schedule.sla_calendar)) do
      schedule.update!(match: !schedule.match)
    end
  end

  test "holiday update invalidates caches for every linked calendar" do
    calendar_holiday = SlaCalendarHoliday.unscoped.detect do |record|
      level_ids_for(record.sla_calendar).any?
    end
    holiday = calendar_holiday.sla_holiday
    level_ids = linked_calendar_ids(holiday).flat_map { |id| level_ids_for(SlaCalendar.find(id)) }

    assert_only_levels_invalidated(level_ids) do
      holiday.update!(name: "#{holiday.name} updated")
    end
  end

  test "calendar holiday update invalidates caches of all competing levels" do
    calendar_holiday = SlaCalendarHoliday.unscoped.detect do |record|
      level_ids_for(record.sla_calendar).any?
    end

    assert_only_levels_invalidated(level_ids_for(calendar_holiday.sla_calendar)) do
      calendar_holiday.update!(match: !calendar_holiday.match)
    end
  end

  test "level update invalidates only its own caches" do
    level = SlaLevel.unscoped.find(SlaCache.unscoped.first.sla_level_id)

    assert_only_levels_invalidated([level.id]) do
      level.update!(name: "#{level.name} updated")
    end
  end

  test "level term update invalidates only caches using its level" do
    term = SlaLevelTerm.unscoped.where(sla_level_id: cached_level_ids).first

    assert_only_levels_invalidated([term.sla_level_id]) do
      term.update!(term: term.term + 1)
    end
  end

  test "destroying a schedule invalidates caches using its calendar" do
    schedule = SlaSchedule.unscoped.detect { |record| level_ids_for(record.sla_calendar).any? }

    assert_only_levels_invalidated(level_ids_for(schedule.sla_calendar)) do
      schedule.destroy!
    end
  end

  test "an invalid schedule does not invalidate caches" do
    existing = SlaSchedule.unscoped.first
    cache_ids = SlaCache.unscoped.order(:id).pluck(:id)
    invalid = SlaSchedule.new(
      sla_calendar: existing.sla_calendar,
      dow: existing.dow,
      start_time: existing.start_time,
      end_time: existing.end_time,
      match: existing.match
    )

    assert_not invalid.save
    assert_equal cache_ids, SlaCache.unscoped.order(:id).pluck(:id)
  end

  test "creating a schedule invalidates its calendar caches" do
    calendar = calendar_with_cached_level
    assert_only_levels_invalidated(level_ids_for(calendar)) do
      SlaSchedule.create!(sla_calendar: calendar, dow: 6,
                          start_time: "09:00", end_time: "10:00", match: true)
    end
  end

  test "creating a calendar holiday invalidates its calendar caches" do
    calendar = calendar_with_cached_level
    holiday = SlaHoliday.create!(name: "New exclusion", date: "2030-01-01")
    assert_only_levels_invalidated(level_ids_for(calendar)) do
      SlaCalendarHoliday.create!(sla_calendar: calendar, sla_holiday: holiday, match: false)
    end
  end

  test "moving a schedule invalidates both calendars" do
    schedule = SlaSchedule.unscoped.find_by!(sla_calendar_id: 1)
    destination = SlaCalendar.find(2)
    ids = level_ids_for(schedule.sla_calendar) + level_ids_for(destination)
    assert_only_levels_invalidated(ids) do
      schedule.update!(sla_calendar: destination, dow: 6,
                       start_time: "09:00", end_time: "10:00")
    end
  end

  test "moving a calendar holiday invalidates both calendars" do
    link = SlaCalendarHoliday.unscoped.find_by!(sla_calendar_id: 1)
    destination = SlaCalendar.find(2)
    holiday = SlaHoliday.create!(name: "Moved exclusion", date: "2030-01-01")
    ids = level_ids_for(link.sla_calendar) + level_ids_for(destination)
    assert_only_levels_invalidated(ids) do
      link.update!(sla_calendar: destination, sla_holiday: holiday)
    end
  end

  test "replacing a linked holiday invalidates its calendar" do
    link = SlaCalendarHoliday.unscoped.find_by!(sla_calendar_id: 1)
    holiday = SlaHoliday.create!(name: "Replacement exclusion", date: "2030-01-01")
    assert_only_levels_invalidated(level_ids_for(link.sla_calendar)) do
      link.update!(sla_holiday: holiday)
    end
  end

  test "destroying a linked holiday invalidates all its calendar caches" do
    holiday = SlaCalendarHoliday.unscoped.find_by!(sla_calendar_id: 1).sla_holiday
    ids = linked_calendar_ids(holiday).flat_map { |id| level_ids_for(SlaCalendar.find(id)) }
    assert_only_levels_invalidated(ids) { holiday.destroy! }
    assert_empty SlaCalendarHoliday.unscoped.where(sla_holiday_id: holiday.id)
  end

  test "destroying a calendar holiday invalidates its calendar caches" do
    link = SlaCalendarHoliday.unscoped.find_by!(sla_calendar_id: 1)
    assert_only_levels_invalidated(level_ids_for(link.sla_calendar)) { link.destroy! }
  end

  test "destroying a calendar invalidates its caches and spent caches" do
    calendar = calendar_with_cached_level
    assert_only_levels_invalidated(level_ids_for(calendar)) { calendar.destroy! }
    assert_empty SlaSchedule.unscoped.where(sla_calendar_id: calendar.id)
    assert_empty SlaCalendarHoliday.unscoped.where(sla_calendar_id: calendar.id)
  end

  test "nested schedule deletion invalidates its calendar caches" do
    calendar = calendar_with_cached_level
    schedule = calendar.sla_schedules.first
    assert_only_levels_invalidated(level_ids_for(calendar)) do
      calendar.update!(sla_schedules_attributes: [{id: schedule.id, _destroy: "1"}])
    end
    assert_not SlaSchedule.exists?(schedule.id)
  end

  test "rolling back a calendar change restores caches and spent caches" do
    calendar = calendar_with_cached_level
    cache_ids = SlaCache.unscoped.order(:id).pluck(:id)
    spent_ids = SlaCacheSpent.unscoped.order(:id).pluck(:id)
    assert_not_empty spent_ids
    SlaCalendar.transaction(requires_new: true) do
      assert_only_levels_invalidated(level_ids_for(calendar)) do
        calendar.update!(name: "Rollback calendar")
      end
      raise ActiveRecord::Rollback
    end
    assert_equal cache_ids, SlaCache.unscoped.order(:id).pluck(:id)
    assert_equal spent_ids, SlaCacheSpent.unscoped.order(:id).pluck(:id)
  end

  test "changing a competing calendar invalidates caches on the other level of the same SLA" do
    level = SlaLevel.find(4)
    competing = SlaLevel.find(5)
    assert_equal level.sla_id, competing.sla_id
    assert_not_equal level.sla_calendar_id, competing.sla_calendar_id
    schedule = SlaSchedule.unscoped.find_by!(sla_calendar_id: competing.sla_calendar_id)
    assert_only_levels_invalidated([level.id, competing.id]) do
      schedule.update!(match: !schedule.match)
    end
  end

  test "creating a level invalidates existing candidates for the same SLA" do
    level = SlaLevel.find(4)
    calendar = SlaCalendar.create!(name: "Additional candidate calendar")
    assert_only_levels_invalidated(SlaLevel.unscoped.where(sla_id: level.sla_id).pluck(:id)) do
      SlaLevel.create!(name: "Additional candidate", sla_id: level.sla_id, sla_calendar: calendar)
    end
  end

  test "moving a level invalidates candidates of both the old and new SLA" do
    level = SlaLevel.find(4)
    destination = SlaLevel.find(6).sla
    ids = SlaLevel.unscoped.where(sla_id: [level.sla_id, destination.id]).pluck(:id)
    assert_only_levels_invalidated(ids) { level.update!(sla: destination) }
  end

  test "moving a term invalidates both levels" do
    term = SlaLevelTerm.unscoped.find_by!(sla_level_id: 1)
    destination = SlaLevel.find(2)
    assert_only_levels_invalidated([term.sla_level_id, destination.id]) do
      term.update!(sla_level: destination, sla_type_id: 2)
    end
  end

  test "changing a level calendar invalidates its competing levels" do
    level = SlaLevel.find(4)
    calendar = SlaCalendar.create!(name: "Replacement candidate calendar")
    ids = SlaLevel.unscoped.where(sla_id: level.sla_id).pluck(:id)
    assert_only_levels_invalidated(ids) { level.update!(sla_calendar: calendar) }
  end

  test "creating a term invalidates its level caches" do
    assert_only_levels_invalidated([2]) do
      SlaLevelTerm.create!(sla_level_id: 2, sla_type_id: 2, sla_priority_id: 1, term: 120)
    end
  end

  test "destroying a term invalidates its level caches" do
    term = SlaLevelTerm.unscoped.find_by!(sla_level_id: 1)
    assert_only_levels_invalidated([term.sla_level_id]) { term.destroy! }
  end

  test "destroying a level invalidates its caches and spent caches" do
    level = SlaLevel.find(4)
    assert_only_levels_invalidated([level.id]) { level.destroy! }
  end

  test "a changed competing schedule recalculates the selected level on next read" do
    schedule = SlaSchedule.unscoped.find_by!(sla_calendar_id: 4, dow: 2,
                                            start_time: "00:00:00")
    schedule.update!(match: false)
    issue = Issue.find(34).dup
    issue.subject = "Competing calendar recalculation"
    travel_to(Time.utc(2021, 12, 7, 8, 0)) { issue.save! }
    assert_equal Time.utc(2021, 12, 7, 8, 0), issue.reload.created_on
    assert_equal 4, SlaCache.find_by_issue_id(issue.id).sla_level_id
    cache = SlaCache.unscoped.find_by!(issue_id: issue.id)
    SlaCacheSpent.find_by_issue_and_type_id(issue, 1)
    assert SlaCacheSpent.unscoped.exists?(sla_cache_id: cache.id)

    schedule.update!(match: true)

    assert_not SlaCache.unscoped.exists?(cache.id)
    assert_not SlaCacheSpent.unscoped.exists?(sla_cache_id: cache.id)
    assert_equal 5, SlaCache.find_by_issue_id(issue.id).sla_level_id
  end

  test "custom field update invalidates only levels using that field" do
    assert_only_levels_invalidated(custom_field_level_ids) do
      IssueCustomField.find(1).update!(is_required: false)
    end
  end

  test "custom field description changes preserve caches" do
    field = IssueCustomField.find(1)
    # Normalize the fixture through Redmine, then repopulate an affected cache.
    field.save!
    issue = Issue.find(66)
    SlaCache.find_by_issue_id(issue.id)
    SlaCacheSpent.find_by_issue_and_type_id(issue, 1)
    cache_ids = SlaCache.unscoped.order(:id).pluck(:id)
    spent_ids = SlaCacheSpent.unscoped.order(:id).pluck(:id)
    assert_not_empty cache_ids
    assert_not_empty spent_ids
    assert SlaCache.unscoped.where(sla_level_id: custom_field_level_ids).exists?

    field.update!(description: 'Updated SLA priority field')

    assert_equal cache_ids, SlaCache.unscoped.order(:id).pluck(:id)
    assert_equal spent_ids, SlaCacheSpent.unscoped.order(:id).pluck(:id)
  end

  test "enumeration update invalidates only levels using its field" do
    assert_only_levels_invalidated(custom_field_level_ids) do
      CustomFieldEnumeration.find(1).update!(active: false)
    end
  end

  test "enumeration creation invalidates only levels using its field" do
    assert_only_levels_invalidated(custom_field_level_ids) do
      CustomFieldEnumeration.create!(custom_field_id: 1, name: 'New priority', position: 5)
    end
  end

  test "moving an enumeration invalidates levels using its previous field" do
    assert_only_levels_invalidated(custom_field_level_ids) do
      CustomFieldEnumeration.find(1).update!(custom_field_id: 2)
    end
  end

  test "enumeration deletion without reassignment invalidates affected levels" do
    assert_only_levels_invalidated(custom_field_level_ids) do
      CustomFieldEnumeration.find(4).destroy
    end
  end

  test "enumeration deletion with reassignment invalidates affected levels" do
    enumeration = CustomFieldEnumeration.find(1)
    values = enumeration.custom_values.pluck(:id)
    assert_not_empty values

    assert_only_levels_invalidated(custom_field_level_ids) do
      enumeration.destroy(CustomFieldEnumeration.find(2))
    end
    assert_equal ['2'], CustomValue.where(id: values).distinct.pluck(:value)
  end

  test "custom field deletion removes affected caches" do
    assert_only_levels_invalidated(custom_field_level_ids) do
      IssueCustomField.find(1).destroy!
    end
  end

  test "unrelated custom field changes preserve caches" do
    cache_ids = SlaCache.unscoped.order(:id).pluck(:id)
    IssueCustomField.find(2).update!(is_required: true)
    CustomFieldEnumeration.find(5).update!(active: false)
    assert_equal cache_ids, SlaCache.unscoped.order(:id).pluck(:id)
  end

  test "invalid enumeration update preserves caches" do
    cache_ids = SlaCache.unscoped.order(:id).pluck(:id)
    assert_not CustomFieldEnumeration.find(1).update(name: '')
    assert_equal cache_ids, SlaCache.unscoped.order(:id).pluck(:id)
  end

  test "rolled back enumeration update restores caches" do
    cache_ids = SlaCache.unscoped.order(:id).pluck(:id)
    CustomFieldEnumeration.transaction(requires_new: true) do
      CustomFieldEnumeration.find(1).update!(active: false)
      raise ActiveRecord::Rollback
    end
    assert_equal cache_ids, SlaCache.unscoped.order(:id).pluck(:id)
  end

  private

  def custom_field_level_ids
    SlaLevel.unscoped.where(custom_field_id: 1).pluck(:id)
  end

  def cached_level_ids
    SlaCache.unscoped.distinct.pluck(:sla_level_id)
  end

  def calendar_with_cached_level
    SlaCalendar.find(SlaLevel.unscoped.where(id: cached_level_ids).first.sla_calendar_id)
  end

  def level_ids_for(calendar)
    sla_ids = SlaLevel.unscoped.where(sla_calendar_id: calendar.id).pluck(:sla_id)
    SlaLevel.unscoped.where(sla_id: sla_ids).pluck(:id)
  end

  def linked_calendar_ids(holiday)
    SlaCalendarHoliday.unscoped.where(sla_holiday_id: holiday.id).pluck(:sla_calendar_id)
  end

  def assert_only_levels_invalidated(level_ids)
    affected_ids = SlaCache.unscoped.where(sla_level_id: level_ids).pluck(:id)
    unaffected_ids = SlaCache.unscoped.where.not(sla_level_id: level_ids).order(:id).pluck(:id)
    assert_not_empty affected_ids

    assert_not_empty SlaCacheSpent.unscoped.where(sla_cache_id: affected_ids).pluck(:id)
    unaffected_spent_ids = SlaCacheSpent.unscoped.where(sla_cache_id: unaffected_ids).order(:id).pluck(:id)

    yield

    assert_empty SlaCache.unscoped.where(id: affected_ids)
    assert_equal unaffected_ids, SlaCache.unscoped.where(id: unaffected_ids).order(:id).pluck(:id)
    assert_empty SlaCacheSpent.unscoped.where(sla_cache_id: affected_ids)
    assert_equal unaffected_spent_ids,
                 SlaCacheSpent.unscoped.where(sla_cache_id: unaffected_ids).order(:id).pluck(:id)
  end
end
