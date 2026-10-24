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
  test "calendar metadata changes preserve caches" do
    calendar = calendar_with_cached_level

    assert_cache_queries(0) do
      assert_caches_preserved do
        calendar.update!(name: "#{calendar.name} updated", description: "Updated metadata")
      end
    end
  end

  test "schedule update invalidates caches of all competing levels" do
    schedule = SlaSchedule.unscoped.detect { |record| level_ids_for(record.sla_calendar).any? }

    assert_only_levels_invalidated(level_ids_for(schedule.sla_calendar)) do
      schedule.update!(match: !schedule.match)
    end
  end

  test "holiday date update invalidates caches for every linked calendar" do
    calendar_holiday = SlaCalendarHoliday.unscoped.detect do |record|
      level_ids_for(record.sla_calendar).any?
    end
    holiday = calendar_holiday.sla_holiday
    level_ids = linked_calendar_ids(holiday).flat_map { |id| level_ids_for(SlaCalendar.find(id)) }

    assert_only_levels_invalidated(level_ids) do
      holiday.update!(date: "2030-02-03")
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
      schedule = calendar.sla_schedules.first
      assert_only_levels_invalidated(level_ids_for(calendar)) do
        schedule.update!(match: !schedule.match)
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

  test "holiday name changes preserve caches without dependency queries" do
    holiday = SlaCalendarHoliday.unscoped.find_by!(sla_calendar_id: 1).sla_holiday
    assert_cache_queries(0) do
      assert_caches_preserved { holiday.update!(name: "Renamed holiday") }
    end
  end

  test "holiday name and date changes still invalidate linked calendars" do
    holiday = SlaCalendarHoliday.unscoped.find_by!(sla_calendar_id: 1).sla_holiday
    ids = linked_calendar_ids(holiday).flat_map { |id| level_ids_for(SlaCalendar.find(id)) }
    assert_only_levels_invalidated(ids) do
      holiday.update!(name: "Renamed and moved holiday", date: "2030-02-03")
    end
  end

  test "calendar rename with nested schedule changes still invalidates competing levels" do
    calendar = calendar_with_cached_level
    schedule = calendar.sla_schedules.first
    assert_only_levels_invalidated(level_ids_for(calendar)) do
      calendar.update!(name: "Renamed with schedule", sla_schedules_attributes: [
        {id: schedule.id, match: schedule.match ? "0" : "1"}
      ])
    end
  end

  test "destroying a calendar captures dependencies and deletes caches once for many children" do
    calendar = calendar_with_cached_level
    10.times do |index|
      holiday = SlaHoliday.create!(name: "Extra holiday #{index}", date: Date.new(2030, 1, 1) + index)
      SlaCalendarHoliday.create!(sla_calendar: calendar, sla_holiday: holiday, match: false)
    end
    # Setup changes invalidate caches; repopulate before measuring destruction.
    Rake::Task['sla:update'].execute
    ids = level_ids_for(calendar)
    assert_operator calendar.sla_schedules.count, :>, 1
    calendar.name = "Unsaved metadata"
    assert_only_levels_invalidated(ids) do
      assert_cache_queries(2) { calendar.destroy! }
    end
    assert_empty SlaCalendarHoliday.unscoped.where(sla_calendar_id: calendar.id)
    assert_empty SlaSchedule.unscoped.where(sla_calendar_id: calendar.id)
  end

  test "destroying a holiday captures dependencies and deletes caches once for many links" do
    holiday = SlaHoliday.create!(name: "Shared exclusion", date: "2030-02-03")
    SlaCalendar.find_each do |calendar|
      SlaCalendarHoliday.create!(sla_calendar: calendar, sla_holiday: holiday, match: false)
    end
    Rake::Task['sla:update'].execute
    ids = linked_calendar_ids(holiday).flat_map { |id| level_ids_for(SlaCalendar.find(id)) }
    assert_operator holiday.sla_calendar_holidays.count, :>, 1
    assert_only_levels_invalidated(ids) do
      assert_cache_queries(3) { holiday.destroy! }
    end
    assert_empty SlaCalendarHoliday.unscoped.where(sla_holiday_id: holiday.id)
  end

  test "parent destruction invalidates once after an aborted child destruction" do
    calendar = calendar_with_cached_level
    calendar.sla_schedules.load
    schedule = calendar.sla_schedules.first
    abort_destroy = :abort_sla_cache_test_destruction
    schedule.define_singleton_method(abort_destroy) { throw(:abort) }
    begin
      SlaSchedule.set_callback(:destroy, :before, abort_destroy, if: ->(record) { record.equal?(schedule) })
      assert_caches_preserved { assert_not schedule.destroy }
    ensure
      SlaSchedule.skip_callback(:destroy, :before, abort_destroy)
    end
    assert_only_levels_invalidated(level_ids_for(calendar)) do
      assert_cache_queries(2) { calendar.destroy! }
    end
  end

  test "rolling back a dependent destruction restores configuration links and caches" do
    calendar = calendar_with_cached_level
    schedule_ids = calendar.sla_schedules.order(:id).pluck(:id)
    link_ids = calendar.sla_calendar_holidays.order(:id).pluck(:id)
    assert_not_empty link_ids
    assert_caches_preserved do
      SlaCalendar.transaction(requires_new: true) do
        calendar.destroy!
        raise ActiveRecord::Rollback
      end
    end
    assert SlaCalendar.exists?(calendar.id)
    assert_equal schedule_ids, calendar.sla_schedules.reload.order(:id).pluck(:id)
    assert_equal link_ids, calendar.sla_calendar_holidays.reload.order(:id).pluck(:id)
  end

  test "aborted dependent destruction preserves configuration and caches" do
    calendar = calendar_with_cached_level
    schedule = calendar.sla_schedules.first
    abort_destroy = :abort_sla_cache_test_destruction
    calendar.define_singleton_method(abort_destroy) { throw(:abort) }
    begin
      SlaCalendar.set_callback(:destroy, :before, abort_destroy, if: ->(record) { record.equal?(calendar) })
      assert_caches_preserved { assert_not calendar.destroy }
    ensure
      SlaCalendar.skip_callback(:destroy, :before, abort_destroy)
    end
    assert SlaCalendar.exists?(calendar.id)
    assert SlaSchedule.exists?(schedule.id)
    assert_cache_queries(0) do
      assert_caches_preserved { calendar.update!(name: "Renamed after aborted destruction") }
    end
  end

  private

  def assert_caches_preserved
    cache_ids = SlaCache.unscoped.order(:id).pluck(:id)
    spent_ids = SlaCacheSpent.unscoped.order(:id).pluck(:id)
    assert_not_empty cache_ids
    assert_not_empty spent_ids
    yield
    assert_equal cache_ids, SlaCache.unscoped.order(:id).pluck(:id)
    assert_equal spent_ids, SlaCacheSpent.unscoped.order(:id).pluck(:id)
  end

  # Count dependency SELECTs and cache DELETEs, excluding verification reads.
  def assert_cache_queries(expected)
    queries = []
    subscriber = lambda do |*args|
      sql = args.last[:sql]
      if sql.match?(/\ASELECT.*FROM ["`]?sla_levels["`]?/i) ||
          sql.match?(/\ASELECT.*sla_calendar_id.*FROM ["`]?sla_calendar_holidays["`]?/i) ||
          sql.match?(/\ADELETE FROM ["`]?sla_caches["`]?/i)
        queries << sql
      end
    end
    ActiveSupport::Notifications.subscribed(subscriber, 'sql.active_record') { yield }
    assert_equal expected, queries.size, queries.join("\n")
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
