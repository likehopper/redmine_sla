# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

require File.expand_path('../../application_sla_units_test_case', __FILE__)

class SlaIssueQueryPreloadTest < ApplicationSlaUnitsTestCase
  def setup
    super
    User.current = User.find(1)
  end

  def teardown
    User.current = nil
    super
  end

  # Respect columns and SLA level grouping read the level cache too.
  {
    'SLA level column' => {columns: [:id, :get_sla_level]},
    'SLA respect column' => {columns: [:id, :get_sla_respect_1]},
    'SLA level grouping' => {columns: [:id], group_by: 'get_sla_level'}
  }.each do |description, options|
    test "#{description} loads cache values with a fixed number of queries" do
      query_counts = [1, 5].map do |limit|
        query = sla_issue_query(options[:columns], group_by: options[:group_by])

        statements = sla_cache_queries do
          issues = query.issues(limit: limit)
          assert_equal limit, issues.size
          issues.each(&:get_sla_level)
        end

        assert_equal 1, statements.count { |sql| sql.include?('sla_get_level') }
        assert_equal 1, statements.count { |sql| sql.match?(/\bFROM\s+["`]?sla_caches\b/i) }
        statements.size
      end

      assert_equal query_counts.first, query_counts.last
    end
  end

  test "rows whose project hides SLA values are not evaluated" do
    User.current = User.find(3) # view_sla in projects 1 and 4.
    query = sla_issue_query([:id, :get_sla_level])
    # Columns exist while project 1 grants view_sla; its rows are then hidden.
    Project.find(1).enabled_modules.where(name: 'sla').delete_all

    issues = nil
    statements = sla_cache_queries { issues = query.issues(limit: 5) }

    assert_not_empty issues
    assert_empty statements
    level_column = query.columns.detect { |column| column.name == :get_sla_level }
    assert_nil level_column.value_object(issues.first)
  end

  test "preloaded missing cache is memoized as nil" do
    issue = Issue.find(1)
    SlaCache.preload_for_issues([issue])

    assert_nil issue.get_sla_cache
  end

  test "issue queries without the SLA level column do not evaluate SLA caches" do
    query = sla_issue_query([:id])

    statements = sla_cache_queries { query.issues(limit: 1) }

    assert_empty statements
  end

  private

  def sla_issue_query(column_names, group_by: nil)
    query = IssueQuery.new(name: '_', project: Project.find(1))
    query.filters = {}
    query.available_filters
    query.column_names = column_names
    query.group_by = group_by
    query
  end

  def sla_cache_queries
    statements = []
    subscriber = lambda do |*arguments|
      sql = arguments.last[:sql]
      statements << sql if sql.match?(/\bsla_get_level\b|\bFROM\s+["`]?\bsla_caches\b/i)
    end
    ActiveSupport::Notifications.subscribed(subscriber, 'sql.active_record') { yield }
    statements
  end
end
