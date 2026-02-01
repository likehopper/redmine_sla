# frozen_string_literal: true

# File: redmine_sla/test/helpers/sla_test_helper.rb
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

require File.expand_path('../../../../../test/test_helper', __FILE__)

module RedmineSlaTestHelper
  # Return the plugin-local fixtures directory
  def self.plugin_fixtures_dir
    File.expand_path('../fixtures', __dir__)
  end

  # Configure fixture paths for the given test case class
  # Compatible with Redmine 5 (Rails 6.1) and Redmine 6 (Rails 7+)
  def self.set_fixture_paths!(test_case_class)
    dir = plugin_fixtures_dir

    if test_case_class.respond_to?(:fixture_paths=)
      # Rails 7+ supports multiple fixture paths
      test_case_class.fixture_paths = [dir]
    elsif test_case_class.respond_to?(:fixture_path=)
      # Rails 6.1 supports a single fixture path
      test_case_class.fixture_path = dir
    else
      raise "Cannot set fixture path(s) on #{test_case_class}"
    end
  end
end

module RedmineSlaTestBootstrap
  # Minimal Redmine fixtures required for the plugin to operate
  CORE_FIXTURES = %i[
    users
    email_addresses
    enumerations
    issue_statuses
    trackers
    workflows
  ].freeze

  # Fixtures specific to the SLA plugin logic
  SLA_FIXTURES = %i[
    members
    roles
    member_roles
    custom_field_enumerations
    custom_fields
    custom_fields_trackers
    custom_fields_projects
    projects
    issues
    journals
    journal_details
    custom_values
    enabled_modules
    projects_trackers
    sla_project_trackers
    slas
    sla_calendars
    sla_holidays
    sla_calendar_holidays
    sla_schedules
    sla_types
    sla_levels
    sla_level_terms
    sla_statuses
  ].freeze

  # Return the list of fixture names to load
  # SLA fixtures can be excluded for lightweight tests
  def self.fixture_names(include_sla: true)
    include_sla ? (CORE_FIXTURES + SLA_FIXTURES) : CORE_FIXTURES
  end

  # Ensure the SLA cache is up to date for tests
  def self.ensure_update_sla!
    # Allow SLA update to be skipped explicitly
    return if ENV['SKIP_SLA_UPDATE'] == '1'

    # Detect whether a transaction is currently open
    had_transaction = ActiveRecord::Base.connection.transaction_open?

    # Close the transaction to allow persistent writes
    ActiveRecord::Base.connection.commit_db_transaction if had_transaction

    begin
      # Load Rake tasks if not already loaded
      require 'rake'
      task_name = 'redmine:plugins:redmine_sla:update_sla'
      Rails.application.load_tasks unless Rake::Task.task_defined?(task_name)

      # Run the SLA cache update task once
      task = Rake::Task[task_name]
      task.invoke unless task.already_invoked
    rescue => e
      # Do not fail the test suite on SLA update errors
      warn "[redmine_sla] SLA cache update failed: #{e.message}"
    ensure
      # Restore the transaction state expected by the test framework
      ActiveRecord::Base.connection.begin_db_transaction if had_transaction
    end
  end
end