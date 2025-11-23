# frozen_string_literal: true

# Redmine SLA - Redmine Plugin
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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')
require File.expand_path(File.dirname(__FILE__) + '/assertion_helpers')
require File.expand_path(File.dirname(__FILE__) + '/object_helpers')

# --- Ensure Rake and tasks are available (Rails 7 / Redmine 6 compatibility) ---
require 'rake'

# Load general Rails tasks if not already defined.
# In Redmine 5, Rake was loaded by default through `rake test`.
# In Redmine 6 (Rails 7+), tests are run via `rails test` and Rake is not preloaded.
Rails.application.load_tasks unless Rake::Task.task_defined?('environment')

# Explicitly load the plugin's .rake file if the task isn't already defined.
# This makes sure plugin-specific tasks like `update_sla` are available during tests.
unless Rake::Task.task_defined?('redmine:plugins:redmine_sla:update_sla')
  task_file = File.expand_path('../../lib/tasks/redmine_sla.rake', __dir__)
  load task_file if File.exist?(task_file)
end

include AssertionHelpers
include ObjectHelpers

# -----------------------------------------------------------------------------
# Load fixtures for Redmine and the SLA plugin.
# This helper ensures all necessary test data is available before executing tests.
# -----------------------------------------------------------------------------
def plugin_fixtures
  fixtures_directory = "#{File.dirname(__FILE__)}/fixtures/"

  fixture_names = [
    :users,
    :email_addresses,
    :roles,
    :enumerations,
    :custom_field_enumerations,
    :custom_fields,
    :issue_statuses,
    :trackers,
    :custom_fields_trackers,
    :workflows,
    :slas,
    :sla_calendars,
    :sla_holidays,
    :sla_calendar_holidays,
    :sla_schedules,
    :sla_types,
    :sla_levels,
    :sla_level_terms,
    :sla_statuses,
    :projects,
    :custom_fields_projects,
    :members,
    :member_roles,
    :projects_trackers,
    :sla_project_trackers,
    :enabled_modules,
    :issues,
    :journals,
    :journal_details,
    :custom_values
  ]

  if ActiveRecord::VERSION::MAJOR >= 4
    ActiveRecord::FixtureSet.create_fixtures fixtures_directory, fixture_names
  else
    ActiveRecord::Fixtures.create_fixtures fixtures_directory, fixture_names
  end
end

# -----------------------------------------------------------------------------
# Execute the SLA update Rake task, ensuring it is defined and reusable.
# -----------------------------------------------------------------------------
def execute_update_sla_task
  name = 'redmine:plugins:redmine_sla:update_sla'
  raise "Rake task #{name} is not defined" unless Rake::Task.task_defined?(name)
  Rake::Task[name].reenable # Allow task to be run multiple times within tests
  Rake::Task[name].invoke
end

# -----------------------------------------------------------------------------
# Initialize fixtures and trigger SLA task execution for consistent test setup.
# -----------------------------------------------------------------------------
plugin_fixtures
execute_update_sla_task