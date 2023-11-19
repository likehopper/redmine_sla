require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

require File.expand_path(File.dirname(__FILE__) + '/object_helpers')
include ObjectHelpers

def plugin_fixtures

  fixtures_directory = "#{File.dirname(__FILE__)}/fixtures/"

  fixture_names = [
    :users,
    :email_addresses,
    :roles,
    :enumerations,
    :issue_statuses,
    :trackers,
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
    :members,
    :member_roles,
    :projects_trackers,
    :sla_project_trackers,
    :enabled_modules,
    :issues,
    :journals,
    :journal_details
  ]

  if ActiveRecord::VERSION::MAJOR >= 4
    ActiveRecord::FixtureSet.create_fixtures fixtures_directory, fixture_names
  else
    ActiveRecord::Fixtures.create_fixtures fixtures_directory, fixture_names
  end

end

plugin_fixtures

#module ActionController::TestCase::Behavior
#  def process_patched(action, method, *args)
#    options = args.extract_options!
#    if options.present?
#      params = options.delete(:params)
#      options = options.merge(params) if params.present?
#      args << options
#    end
#    process_unpatched(action, method, *args)
#  end
#end
