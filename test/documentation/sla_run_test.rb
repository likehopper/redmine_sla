# frozen_string_literal: true

# File: redmine_sla/test/documentation/sla_creation_documentation_test.rb
# Redmine SLA - Redmine's Plugin
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require_relative "../application_sla_documentation_test_case"

require_relative "modules/00_all_modules"

# Fixture helpers shared by all dynamically generated test classes
module SlaDocumentationFixtureHelpers

  # Tables written by documentation tests, in safe deletion order.
  # CORE_FIXTURES (users, trackers, roles, issue_statuses, …) are intentionally
  # excluded — they must remain intact between suites.
  DOC_TEST_TABLES = %w[
    sla_logs
    sla_caches
    sla_cache_spents
    sla_project_trackers
    sla_level_terms
    sla_levels
    sla_statuses
    sla_calendar_holidays
    sla_holidays
    sla_schedules
    sla_calendars
    sla_types
    slas
    journal_details
    journals
    custom_values
    issues
    custom_field_enumerations
    custom_fields_trackers
    custom_fields_projects
    custom_fields
    enabled_modules
    projects_trackers
    member_roles
    members
    projects
  ].freeze

  # Truncate all documentation-written tables so the next suite starts clean.
  # Called once per test class via a class-level flag in the setup block.
  def reset_sla_test_data!
    conn = ActiveRecord::Base.connection
    existing = DOC_TEST_TABLES.select { |t| conn.table_exists?(t) }
    conn.disable_referential_integrity do
      existing.each { |t| conn.execute("DELETE FROM #{conn.quote_table_name(t)}") }
    end
  end

  def load_doc_fixtures!(suite:)
    @current_suite = suite
    @fixtures = doc_fixtures(suite: suite)
  end

  def doc_fixtures(suite:)
    suite = suite.to_s.strip
    suite = "all" if suite.empty?

    @doc_fixtures_cache ||= {}
    return @doc_fixtures_cache[suite] if @doc_fixtures_cache.key?(suite)

    base_path = Rails.root.join("plugins", "redmine_sla", "test", "documentation")

    sub_dirs = []
    if suite != "all"
      target_dir = base_path.join(suite)
      unless Dir.exist?(target_dir)
        raise ArgumentError, "Documentation folder not found for SUITE=#{suite} (expected #{target_dir})"
      end
      sub_dirs << target_dir
    else
      sub_dirs = Dir.glob(base_path.join("*/")).map { |d| Pathname.new(d) }
      sub_dirs.reject! { |d| d.basename.to_s == "modules" }
      sub_dirs.sort_by! { |d| d.basename.to_s }
    end

    fixtures = {}

    sub_dirs.each do |dir|
      Dir[dir.join("*.yml").to_s].sort.each do |path|
        key  = File.basename(path, ".yml")
        data = YAML.load_file(path)

        if data.is_a?(Hash) && data.key?(key)
          content = data[key]

          if fixtures[key].is_a?(Array) && content.is_a?(Array)
            fixtures[key] += content
          elsif fixtures[key].is_a?(Hash) && content.is_a?(Hash)
            fixtures[key].merge!(content)
          else
            fixtures[key] = content
          end
        end
      end
    end

    @doc_fixtures_cache[suite] = fixtures
  end

  # Helper to retrieve data for a specific entity
  # @param key [String, Symbol] The name of the fixture set (e.g., :slas)
  def fixture!(key)
    key = key.to_s
    unless @fixtures && @fixtures.key?(key)
      raise "Fixtures not loaded for '#{key}'. Ensure the YAML file exists in the documentation suite folder."
    end
    @fixtures[key]
  end

end

# Determine which suites to run.
# When SUITE is not set (or "all"), one isolated test class is generated per
# example folder so that each suite's 12 tests run completely before the next
# suite starts, instead of all example-01 SLAs + all example-02 SLAs being
# created together in test_01_sla, then all types together in test_02, etc.
_base_path = Rails.root.join("plugins", "redmine_sla", "test", "documentation")
_suite_env = (ENV["SUITE"] || "").strip

_suites = if _suite_env.empty? || _suite_env == "all"
  Dir.glob(_base_path.join("*/"))
    .map  { |d| File.basename(d) }
    .reject { |d| d == "modules" }
    .sort
else
  [_suite_env]
end

_suites.each do |_suite_name|
  _class_name = "SlaRunTest_#{_suite_name.gsub('-', '_')}"

  klass = Class.new(ApplicationSlaDocumentationTestCase) do
    include RedmineSlaDocumentationModules
    include SlaDocumentationFixtureHelpers
  end

  # Capture suite name in a local variable so the setup block closes over the
  # correct value for each iteration.
  _captured = _suite_name
  klass.class_eval do
    setup do
      # Reset DB once before the first test of this suite class.
      # Minitest creates a new instance per test, so we use a class-level flag.
      unless self.class.instance_variable_get(:@sla_suite_prepared)
        self.class.instance_variable_set(:@sla_suite_prepared, true)
        reset_sla_test_data!
      end
      load_doc_fixtures!(suite: _captured)
    end
  end

  Object.const_set(_class_name, klass)
end
