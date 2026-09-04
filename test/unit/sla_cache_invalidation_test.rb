# frozen_string_literal: true

# File: redmine_sla/test/unit/sla_cache_invalidation_test.rb
# Purpose:
#   Verifies targeted cache invalidation for every SLA configuration model.
#
# Redmine SLA - Redmine's Plugin

require File.expand_path('../../application_sla_units_test_case', __FILE__)

class SlaCacheInvalidationTest < ApplicationSlaUnitsTestCase
  test "calendar update invalidates only caches using its levels" do
    calendar = calendar_with_cached_level

    assert_only_levels_invalidated(level_ids_for(calendar)) do
      calendar.update!(name: "#{calendar.name} updated")
    end
  end

  test "schedule update invalidates only caches using its calendar" do
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

  test "calendar holiday update invalidates only caches using its calendar" do
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

  private

  def cached_level_ids
    SlaCache.unscoped.distinct.pluck(:sla_level_id)
  end

  def calendar_with_cached_level
    SlaCalendar.find(SlaLevel.unscoped.where(id: cached_level_ids).first.sla_calendar_id)
  end

  def level_ids_for(calendar)
    SlaLevel.unscoped.where(sla_calendar_id: calendar.id).pluck(:id)
  end

  def linked_calendar_ids(holiday)
    SlaCalendarHoliday.unscoped.where(sla_holiday_id: holiday.id).pluck(:sla_calendar_id)
  end

  def assert_only_levels_invalidated(level_ids)
    affected_ids = SlaCache.unscoped.where(sla_level_id: level_ids).pluck(:id)
    unaffected = SlaCache.unscoped.where.not(sla_level_id: level_ids).first
    assert_not_empty affected_ids

    yield

    assert_empty SlaCache.unscoped.where(id: affected_ids)
    assert SlaCache.unscoped.exists?(unaffected.id) if unaffected
    assert_empty SlaCacheSpent.unscoped.where(sla_cache_id: affected_ids)
  end
end
