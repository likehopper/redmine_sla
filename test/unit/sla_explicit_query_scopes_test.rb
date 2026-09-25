# frozen_string_literal: true

require_relative '../application_sla_units_test_case'

class SlaExplicitQueryScopesTest < ApplicationSlaUnitsTestCase
  def setup
    super
    User.current = User.find(1)
  end

  def teardown
    User.current = nil
    super
  end

  {
    SlaLevelQuery => [:sla_levels, %w[sla sla_calendar custom_field]],
    SlaLevelTermQuery => [:sla_level_terms, %w[sla_level sla_type]],
    SlaCacheQuery => [:sla_caches, %w[project sla_level]],
    SlaCacheSpentQuery => [:sla_cache_spents, %w[project sla_level sla_type]],
    SlaProjectTrackerQuery => [:sla_project_trackers, %w[project tracker sla]]
  }.each do |query_class, (finder, columns)|
    columns.each do |column|
      test "#{query_class} sorts and groups by #{column} without losing rows" do
        query = query_class.new(name: '_')
        query.filters = {}
        query.sort_criteria = [[column, 'asc']]
        records = query.public_send(finder)
        assert_not_empty records
        assert_equal query.base_scope.count, records.size
        assert_equal records.map(&:id).uniq.size, records.size

        # These names share an ASCII prefix in the fixtures; nil custom fields
        # are retained by the level query's left join on every adapter.
        values = records.filter_map do |record|
          reference = record.public_send(column)
          column == 'tracker' ? reference.position : reference&.name
        end
        assert_equal values.sort, values

        query.group_by = column
        counts = query.result_count_by_group
        assert_equal records.size, counts.values.sum
        if query_class == SlaCacheSpentQuery && column == 'sla_level'
          assert_equal records.group_by { |r| r.sla_level.name }.transform_values(&:size), counts
        end
        assert_equal records.map(&:id).sort, query.public_send(finder).map(&:id).sort
      end
    end
  end
end
