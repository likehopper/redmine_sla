require File.expand_path('../../test_helper', __FILE__)

class SlaCacheTest < ActiveSupport::TestCase
  #include ActiveModel::Lint::Tests

  fixtures :users,
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

  setup do
  end

  test "#SlaCaches purge" do
    SlaCache.purge()
    assert SlaCache.count(:all).zero?
  end

  test "#SlaCaches count" do
    assert SlaCache.count(:all).zero?
  end

  def test_truth
    assert true
  end

end

