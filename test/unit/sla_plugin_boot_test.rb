# frozen_string_literal: true

require 'open3'
require 'rbconfig'
require File.expand_path('../../application_sla_units_test_case', __FILE__)

class SlaPluginBootTest < ActiveSupport::TestCase
  test 'initializer explicitly loads the database dialect before plugin registration' do
    initializer = Rails.root.join('plugins/redmine_sla/init.rb').read
    require_position = initializer.index('require_relative "lib/redmine_sla/db_dialect"')
    registration_position = initializer.index('Redmine::Plugin.register :redmine_sla')

    assert require_position, 'init.rb must explicitly require RedmineSla::DbDialect'
    assert_operator require_position, :<, registration_position,
      'RedmineSla::DbDialect must load before plugin registration'
  end

  test 'database dialect and SLA query load in a fresh Rails process' do
    script = <<~'RUBY'
      adapter = RedmineSla::DbDialect.adapter
      columns = SlaQuery.new.available_columns.map(&:name)

      abort 'RedmineSla::DbDialect did not resolve an adapter' unless %i[postgresql mysql].include?(adapter)
      abort 'SlaQuery name column did not load' unless columns.include?(:name)
    RUBY

    command = [RbConfig.ruby, Rails.root.join('bin/rails').to_s, 'runner', script]
    stdout, stderr, status = Open3.capture3(
      { 'RAILS_ENV' => Rails.env },
      *command,
      chdir: Rails.root.to_s
    )

    assert status.success?, <<~MESSAGE
      Fresh Rails boot failed (exit #{status.exitstatus}).
      stdout: #{stdout}
      stderr: #{stderr}
    MESSAGE
  end
end
