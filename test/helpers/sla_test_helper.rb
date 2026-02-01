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
  def self.plugin_fixtures_dir
    File.expand_path('../fixtures', __dir__)
  end

  # Works on Redmine 5 (Rails 6.1) and Redmine 6 (Rails 7.x)
  def self.set_fixture_paths!(test_case_class)
    dir = plugin_fixtures_dir

    if test_case_class.respond_to?(:fixture_paths=)
      test_case_class.fixture_paths = [dir]
    elsif test_case_class.respond_to?(:fixture_path=)
      test_case_class.fixture_path = dir
    else
      raise "Cannot set fixture path(s) on #{test_case_class}"
    end
  end
end

module RedmineSlaTestBootstrap

  # fixtures_directory = "#{File.dirname(__FILE__)}/fixtures/"

  # 1. Fixtures minimales pour faire tourner Redmine (vos copies locales)
  CORE_FIXTURES = %i[
    users
    email_addresses
    enumerations
    issue_statuses
    trackers
    workflows
  ].freeze

  # 2. Fixtures spécifiques à la logique SLA
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

  # Méthode pour obtenir la liste selon le besoin
  def self.fixture_names(include_sla: true)
    include_sla ? (CORE_FIXTURES + SLA_FIXTURES) : CORE_FIXTURES
  end

  # Exécution du cache SLA uniquement si nécessaire
  def self.ensure_update_sla!
    return if ENV['SKIP_SLA_UPDATE'] == '1'

      # 1. On sort de la transaction actuelle (celle des fixtures)
      if ActiveRecord::Base.connection.transaction_open?
        ActiveRecord::Base.connection.commit_db_transaction
      end  
    
    # puts "[redmine_sla] Mise à jour du cache SLA..."
    require 'rake'
    unless Rake::Task.task_defined?('redmine:plugins:redmine_sla:update_sla')
      Rails.application.load_tasks
    end
    # Rake::Task['sla:update'].reenable 
    # Rake::Task['redmine:plugins:redmine_sla:update_sla'].reenable    
    unless Rake::Task['redmine:plugins:redmine_sla:update_sla'].already_invoked
      Rake::Task['redmine:plugins:redmine_sla:update_sla'].invoke
    end

    # 3. On force l'écriture finale
      # ActiveRecord::Base.connection.execute("COMMIT") 
      
      # 4. L'ASTUCE : On réouvre une transaction pour que Rails 
      # puisse créer ses SAVEPOINTS (utilisés par with_settings)
      ActiveRecord::Base.connection.begin_db_transaction

  end
  
end