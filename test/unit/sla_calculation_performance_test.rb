# frozen_string_literal: true

# Reports database SLA calculation timings while exercising the same stored
# functions used by the application. These measurements are informational:
# correctness assertions fail the test, but machine-dependent timings do not.

require File.expand_path('../../application_sla_units_test_case', __FILE__)

class SlaCalculationPerformanceTest < ApplicationSlaUnitsTestCase
  test 'report sla_get_level and sla_get_spent timings' do
    connection = ActiveRecord::Base.connection
    issue_ids = SlaCache.unscoped.order(:issue_id).pluck(:issue_id)
    sla_type_ids = SlaType.order(:id).pluck(:id)

    assert_not_empty issue_ids, 'No SLA issue is available for the benchmark'
    assert_not_empty sla_type_ids, 'No SLA type is available for the benchmark'

    RedmineSla::DbDialect.ensure_recursion_depth!

    level_timings = issue_ids.map do |issue_id|
      measure_ms do
        connection.execute(SlaCache.sanitize_sql(["SELECT sla_get_level(?, true);", issue_id]))
      end
    end

    spent_timings = issue_ids.product(sla_type_ids).map do |issue_id, sla_type_id|
      # sla_get_spent has no force flag: remove only this cached result before
      # timing so the function performs the real calculation on every call.
      SlaCacheSpent.unscoped.where(issue_id: issue_id, sla_type_id: sla_type_id).delete_all
      measure_ms do
        connection.execute(
          SlaCacheSpent.sanitize_sql(["SELECT sla_get_spent(?, ?);", issue_id, sla_type_id])
        )
      end
    end

    assert_equal issue_ids.size, level_timings.size
    assert_equal issue_ids.size * sla_type_ids.size, spent_timings.size

    report_timings('sla_get_level', level_timings)
    report_timings('sla_get_spent', spent_timings)
  end

  private

  def measure_ms
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield
    (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1_000
  end

  def report_timings(operation, timings)
    average = timings.sum / timings.size
    puts format(
      '[SLA timing] database=%<database>s operation=%<operation>s calls=%<calls>d ' \
      'min=%<min>.3fms max=%<max>.3fms avg=%<average>.3fms',
      database: database_name,
      operation: operation,
      calls: timings.size,
      min: timings.min,
      max: timings.max,
      average: average
    )
  end

  def database_name
    return ActiveRecord::Base.connection.adapter_name unless RedmineSla::DbDialect.adapter == :mysql

    version = ActiveRecord::Base.connection.select_value('SELECT VERSION()').to_s
    version.include?('MariaDB') ? 'MariaDB' : 'MySQL'
  end
end
