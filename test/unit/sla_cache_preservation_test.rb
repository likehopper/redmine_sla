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

# File: redmine_sla/test/unit/sla_cache_preservation_test.rb
# Purpose:
#   Changes that cannot affect an SLA level, term or spent time must keep the
#   caches and calculation data they do not depend on (no over-invalidation).
#   The invalidating counterparts are in sla_cache_invalidation_test.rb,
#   sla_issue_cache_freshness_test.rb and sla_project_module_test.rb.
#
# Redmine SLA - Redmine's Plugin

require File.expand_path('../../application_sla_units_test_case', __FILE__)

class SlaCachePreservationTest < ApplicationSlaUnitsTestCase
  test "saving an issue without level input changes keeps its cache and spent rows" do
    issue = Issue.find(4)
    cache_id, spent_ids = populated_issue_cache(issue)

    assert_caches_preserved do
      issue.update!(subject: "#{issue.subject} renamed", description: "Updated description")
    end
    assert SlaCache.unscoped.exists?(cache_id)
    assert_equal spent_ids, SlaCacheSpent.unscoped.where(issue_id: issue.id).order(:id).pluck(:id)
  end

  test "changing a custom field not used by any level keeps the issue cache" do
    issue = Issue.find(4)
    field = IssueCustomField.create!(name: 'Unrelated field', field_format: 'string',
                                     is_for_all: true, trackers: [issue.tracker])
    assert_not SlaLevel.unscoped.where(custom_field_id: field.id).exists?
    issue = Issue.find(issue.id)
    assert_includes issue.available_custom_fields, field
    cache_id, = populated_issue_cache(issue)

    issue.custom_field_values = { field.id.to_s => 'changed value' }
    assert_caches_preserved { issue.save! }

    assert_equal 'changed value', Issue.find(issue.id).custom_field_value(field)
    assert SlaCache.unscoped.exists?(cache_id)
  end

  test "renaming, repositioning or deactivating a priority keeps caches" do
    priority = IssuePriority.find(1)
    native_level_ids = SlaLevel.unscoped.joins(:sla_level_terms)
                               .where(custom_field_id: nil, sla_level_terms: { sla_priority_id: priority.id })
                               .distinct.pluck(:id)
    # The priority must be an input of cached levels, or preservation proves nothing.
    assert SlaCache.unscoped.where(sla_level_id: native_level_ids).exists?

    assert_caches_preserved { priority.update!(name: 'Renamed low priority') }
    assert_caches_preserved { priority.update!(position: IssuePriority.maximum(:position) + 1) }
    assert_caches_preserved { priority.update!(active: false) }
    assert_not priority.reload.active
  end

  test "a holiday linked to one calendar invalidates only the SLAs of that calendar" do
    calendar = calendar_with_cached_level
    holiday = SlaHoliday.create!(name: 'Single calendar exclusion', date: '2030-02-03')
    SlaCalendarHoliday.create!(sla_calendar: calendar, sla_holiday: holiday, match: false)
    # Setup changes invalidate the calendar caches; repopulate before measuring.
    Rake::Task['sla:update'].execute
    assert_equal [calendar.id], SlaCalendarHoliday.unscoped.where(sla_holiday_id: holiday.id).pluck(:sla_calendar_id)

    assert_only_affected_slas_invalidated(level_ids_for(calendar)) do
      holiday.update!(date: '2030-02-04')
    end
  end

  test "disabling the SLA module on one project keeps other projects caches" do
    project = Project.find(1)
    assert_not_nil Issue.find(4).get_sla_level
    assert SlaCache.unscoped.where(project_id: project.id).exists?
    other_cache_ids = SlaCache.unscoped.where.not(project_id: project.id).order(:id).pluck(:id)
    other_spent_ids = SlaCacheSpent.unscoped.where.not(project_id: project.id).order(:id).pluck(:id)
    assert_not_empty other_cache_ids
    assert_not_empty other_spent_ids

    project.disable_module!(:sla)

    assert_not SlaCache.unscoped.where(project_id: project.id).exists?
    assert_equal other_cache_ids, SlaCache.unscoped.where.not(project_id: project.id).order(:id).pluck(:id)
    assert_equal other_spent_ids, SlaCacheSpent.unscoped.where.not(project_id: project.id).order(:id).pluck(:id)
  end

  test "a level metadata save keeps its terms" do
    level = SlaLevel.unscoped.where(id: cached_level_ids).detect { |record| record.sla_level_terms.exists? }
    assert_not_nil level
    term_ids = SlaLevelTerm.unscoped.where(sla_level_id: level.id).order(:id).pluck(:id)

    assert_caches_preserved do
      level.update!(name: "#{level.name} renamed", description: 'Updated metadata')
    end
    assert_equal term_ids, SlaLevelTerm.unscoped.where(sla_level_id: level.id).order(:id).pluck(:id)
  end

  private

  # Returns the cache id and spent row ids after asserting they exist.
  def populated_issue_cache(issue)
    assert_not_nil issue.get_sla_level
    SlaType.all.each { |sla_type| issue.get_sla_spent(sla_type.id) }
    cache = SlaCache.unscoped.find_by(issue_id: issue.id)
    assert_not_nil cache
    spent_ids = SlaCacheSpent.unscoped.where(issue_id: issue.id).order(:id).pluck(:id)
    assert_not_empty spent_ids
    [cache.id, spent_ids]
  end

  def assert_caches_preserved
    cache_ids = SlaCache.unscoped.order(:id).pluck(:id)
    spent_ids = SlaCacheSpent.unscoped.order(:id).pluck(:id)
    assert_not_empty cache_ids
    assert_not_empty spent_ids
    yield
    assert_equal cache_ids, SlaCache.unscoped.order(:id).pluck(:id)
    assert_equal spent_ids, SlaCacheSpent.unscoped.order(:id).pluck(:id)
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

  def assert_only_affected_slas_invalidated(level_ids)
    sla_ids = SlaLevel.unscoped.where(id: level_ids).distinct.pluck(:sla_id)
    affected_level_ids = SlaLevel.unscoped.where(sla_id: sla_ids).select(:id)
    affected_ids = SlaCache.unscoped.where(sla_level_id: affected_level_ids).pluck(:id)
    unaffected_ids = SlaCache.unscoped.where.not(sla_level_id: affected_level_ids).order(:id).pluck(:id)
    assert_not_empty affected_ids
    assert_not_empty unaffected_ids
    unaffected_spent_ids = SlaCacheSpent.unscoped.where(sla_cache_id: unaffected_ids).order(:id).pluck(:id)
    assert_not_empty unaffected_spent_ids

    yield

    assert_empty SlaCache.unscoped.where(id: affected_ids)
    assert_empty SlaCacheSpent.unscoped.where(sla_cache_id: affected_ids)
    assert_equal unaffected_ids, SlaCache.unscoped.where(id: unaffected_ids).order(:id).pluck(:id)
    assert_equal unaffected_spent_ids,
                 SlaCacheSpent.unscoped.where(sla_cache_id: unaffected_ids).order(:id).pluck(:id)
  end
end
