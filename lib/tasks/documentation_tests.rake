# frozen_string_literal: true

# File: redmine_sla/lib/tasks/documentation_tests.rake
# Rake task for documentation tests only

# plugins/redmine_sla/lib/tasks/documentation_test.rake
# frozen_string_literal: true

namespace :redmine do
  namespace :plugins do
    namespace :test do

      # Force Minitest to use seed 0 for deterministic test order
      ARGV.unshift('--seed', '0') unless ARGV.include?('--seed')

      desc "Run documentation system tests for redmine_sla"
      task :documentation => ['db:test:prepare', :environment] do

        # Variable preparation
        name       = ENV['NAME'] || ENV['PLUGIN'] || 'redmine_sla'
        # suite      = ENV['SUITE'] || '**'
        directory  = Rails.root.join('plugins', name).join("test/documentation")
        # test_files = Dir["#{directory}/#{suite}/*_test.rb"]
        test_files = Dir["#{directory}/*_test.rb"]

        # Require the original ApplicationSystemTestCase from Redmine core
        require Rails.root.join("test", "application_system_test_case.rb")

        # The loading of fixture metadata is forced.
        require 'active_record/fixtures'

        # 3) Load your documentation test files
        test_files.each { |file| require file }

      end
    end
  end
end