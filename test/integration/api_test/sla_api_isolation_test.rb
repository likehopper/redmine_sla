# frozen_string_literal: true
# File: redmine_sla/test/integration/api_test/sla_api_isolation_test.rb
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Redmine SLA - service level agreement plugin
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

require_relative '../../application_sla_api_test_case'

# Authentication, permission, module and project isolation matrix for every
# REST endpoint of the plugin, in JSON and XML.
#
# Fixture roles: manager has view_sla and manage_sla in projects 1 to 6 (SLA
# module enabled in projects 1 to 4 only), developer has view_sla in projects
# 1 and 4, reporter is a member without SLA permission, other is not a member.
class Redmine::ApiTest::SlaApiIsolationTest < ApplicationSlaApiTestCase
  FORMATS = %w[json xml].freeze
  TMA = 'project-sla-tests-tma'          # id 1
  STD = 'project-sla-tests-std'          # id 2
  WITHOUT_MODULE = 'another-project-without-sla' # id 5, manager member, module disabled
  DEVELOPER_PROJECT_IDS = [1, 4].freeze
  ALL_STATUSES = {'issue.status_id' => '*'}.freeze

  # Every plugin table, so a denied request that writes anywhere is detected.
  SLA_MODELS = [
    Sla, SlaType, SlaStatus, SlaHoliday, SlaCalendar, SlaCalendarHoliday, SlaSchedule,
    SlaLevel, SlaLevelTerm, SlaProjectTracker, SlaCache, SlaCacheSpent
  ].freeze

  # Authentication

  test 'missing and invalid API keys are rejected on every endpoint without changing data' do
    endpoints = read_endpoints + admin_write_endpoints + project_write_endpoints(TMA, 1) + global_cache_write_endpoints
    [{}, {'X-Redmine-API-Key' => 'invalid-sla-api-key'}].each do |headers|
      each_request(endpoints) do |verb, path, params|
        assert_api_denied verb, path, params, headers, [401]
      end
    end
  end

  test 'valid administrator API key reaches every read endpoint and can write' do
    each_request(read_endpoints) do |verb, path, params|
      send(verb, path, params: params, headers: api_key_headers('admin'))
      assert_response :success, "#{verb.upcase} #{path}"
      assert_sla_payload
    end
    assert_difference 'SlaType.count', 1 do
      post '/sla/types.json', params: {sla_type: {name: 'Isolation API key type'}},
        headers: api_key_headers('admin')
    end
    assert_response :created
  end

  test 'API key of a locked user is rejected' do
    headers = api_key_headers('developer')
    User.find_by_login!('developer').lock!
    each_request(project_read_endpoints(TMA, 1)) do |verb, path, params|
      assert_api_denied verb, path, params, headers, [401]
    end
  end

  # Permissions

  test 'members without view_sla and non members are forbidden on every endpoint' do
    endpoints = read_endpoints + admin_write_endpoints + project_write_endpoints(TMA, 1) + global_cache_write_endpoints
    %w[reporter other].each do |login|
      each_request(endpoints) do |verb, path, params|
        assert_api_denied verb, path, params, api_key_headers(login), [403]
      end
    end
  end

  test 'view_sla grants project reads but no administration read' do
    each_request(project_read_endpoints(TMA, 1)) do |verb, path, params|
      send(verb, path, params: params, headers: api_key_headers('developer'))
      assert_response :success, "#{verb.upcase} #{path}"
      assert_sla_payload
    end
    each_request(admin_read_endpoints) do |verb, path, params|
      assert_api_denied verb, path, params, api_key_headers('developer'), [403]
    end
  end

  test 'view_sla without manage_sla cannot write and leaves data untouched' do
    endpoints = admin_write_endpoints + project_write_endpoints(TMA, 1) + global_cache_write_endpoints
    each_request(endpoints) do |verb, path, params|
      assert_api_denied verb, path, params, api_key_headers('developer'), [403]
    end
  end

  test 'manage_sla can refresh destroy and purge caches of its project' do
    headers = api_key_headers('manager')
    cache = cache_with_spents(1)
    spent_ids = cache.sla_cache_spents.pluck(:id)

    patch "/projects/#{TMA}/sla/caches/#{cache.id}/refresh.json", headers: headers
    assert_response :success
    assert_empty SlaCacheSpent.where(id: spent_ids), 'refresh must rebuild the spent rows'
    assert cache.sla_cache_spents.reload.exists?

    spent = SlaCacheSpent.where(project_id: 1).order(:id).first
    delete "/sla/cache_spents/#{spent.id}.xml", headers: headers
    assert_response :success
    assert_not SlaCacheSpent.exists?(spent.id)

    delete "/sla/caches/#{cache.id}.xml", headers: headers
    assert_response :success
    assert_not SlaCache.exists?(cache.id)

    other_project_caches = SlaCache.where.not(project_id: 1).count
    patch "/projects/#{TMA}/sla/caches/purge.json", headers: headers
    assert_response :success
    assert_equal 0, SlaCache.where(project_id: 1).count
    assert_equal other_project_caches, SlaCache.where.not(project_id: 1).count
  end

  # Module

  test 'disabling the SLA module hides the project from reads and writes' do
    project = Project.find(1)
    cache = SlaCache.where(project_id: 1).order(:id).first

    get "/projects/#{TMA}/sla/caches.json", params: ALL_STATUSES, headers: api_key_headers('manager')
    assert_response :success
    assert_operator response.parsed_body['total_count'], :>, 0

    # Project#disable_module! purges the caches; deleting the module row keeps
    # them, so the API must deny them on the module check alone.
    EnabledModule.where(project_id: project.id, name: 'sla').delete_all
    assert_not project.reload.module_enabled?(:sla)
    assert SlaCache.exists?(cache.id)
    endpoints = project_read_endpoints(TMA, 1) + project_write_endpoints(TMA, 1)
    %w[admin manager].each do |login|
      each_request(endpoints) do |verb, path, params|
        assert_api_denied verb, path, params, api_key_headers(login), [403, 404]
      end
    end

    # The global list of a member of both projects keeps the other project only.
    FORMATS.each do |format|
      get "/sla/caches.#{format}", params: ALL_STATUSES.merge(limit: 100), headers: api_key_headers('developer')
      assert_response :success
      total_count, items = index_payload('sla_caches', 'sla_cache')
      assert_equal SlaCache.where(project_id: 4).count, total_count
      assert_equal [4], items.map { |item| item['project_id'].to_i }.uniq
      assert_not_includes items.map { |item| item['id'].to_i }, cache.id
    end
  end

  test 'a project without the SLA module is forbidden even for its manager' do
    headers = api_key_headers('manager')
    each_request(project_read_endpoints(WITHOUT_MODULE, 5)) do |verb, path, params|
      assert_api_denied verb, path, params, headers, [403]
    end
    tracker_params = {sla_project_tracker: {project_id: 5, tracker_id: 1, sla_id: 1}}
    [
      [:patch, "/projects/#{WITHOUT_MODULE}/sla/caches/purge", nil],
      [:post, "/projects/#{WITHOUT_MODULE}/sla/trackers", tracker_params],
      [:post, '/sla/project_trackers', tracker_params]
    ].each do |verb, path, params|
      FORMATS.each do |format|
        assert_api_denied verb, "#{path}.#{format}", params, headers, [403]
      end
    end
  end

  # Cross project

  test 'records of another project are not readable by id or through a mismatched project' do
    headers = api_key_headers('developer')
    foreign_cache = SlaCache.where(project_id: 2).order(:id).first
    foreign_spent = SlaCacheSpent.where(project_id: 2).order(:id).first
    foreign_sla = Sla.find(3)
    foreign_level = SlaLevel.find_by!(sla_id: foreign_sla.id)
    foreign_calendar = foreign_level.sla_calendar
    own_project_4_sla = Sla.find(7)
    # The foreign records must really be outside the developer projects.
    assert_empty foreign_sla.sla_project_trackers.where(project_id: DEVELOPER_PROJECT_IDS)
    assert_empty foreign_calendar.sla_levels.joins(sla: :sla_project_trackers).
      where(sla_project_trackers: {project_id: DEVELOPER_PROJECT_IDS})
    assert_equal [4], own_project_4_sla.sla_project_trackers.pluck(:project_id)

    endpoints = [
      [:get, "/sla/caches/#{foreign_cache.id}"],
      [:get, "/projects/#{TMA}/sla/caches/#{foreign_cache.id}"],
      [:get, "/projects/#{STD}/sla/caches/#{foreign_cache.id}"],
      [:get, "/sla/cache_spents/#{foreign_spent.id}"],
      [:get, "/sla/caches", ALL_STATUSES.merge(project_id: 2)],
      [:get, "/sla/cache_spents", ALL_STATUSES.merge(project_id: 2)],
      [:get, "/sla/slas/#{foreign_sla.id}"],
      [:get, "/projects/#{TMA}/sla/slas/#{foreign_sla.id}"],
      [:get, "/projects/#{TMA}/sla/slas/#{own_project_4_sla.id}"],
      [:get, "/projects/#{STD}/sla/slas"],
      [:get, "/sla/levels/#{foreign_level.id}"],
      [:get, "/projects/#{TMA}/sla/levels/#{foreign_level.id}"],
      [:get, "/projects/#{STD}/sla/levels"],
      [:get, "/sla/calendars/#{foreign_calendar.id}"],
      [:get, "/projects/#{TMA}/sla/calendars/#{foreign_calendar.id}"],
      [:get, "/projects/#{STD}/sla/calendars"]
    ]
    each_request(endpoints) do |verb, path, params|
      assert_api_denied verb, path, params, headers, [403, 404]
    end

    # Positive counterpart: the same user reads the records of its own projects.
    [
      "/sla/caches/#{SlaCache.where(project_id: 1).order(:id).first.id}",
      "/sla/cache_spents/#{SlaCacheSpent.where(project_id: 4).order(:id).first.id}",
      "/sla/slas/#{own_project_4_sla.id}",
      "/projects/#{TMA}/sla/slas/1",
      "/projects/#{TMA}/sla/levels/1",
      "/projects/#{TMA}/sla/calendars/1"
    ].each do |path|
      FORMATS.each do |format|
        get "#{path}.#{format}", headers: headers
        assert_response :success, path
        assert_sla_payload
      end
    end
  end

  test 'a manager of one project cannot change caches of another project' do
    restrict_manager_to_project_1
    headers = api_key_headers('manager')
    own_cache = cache_with_spents(1)
    foreign_cache = cache_with_spents(2)
    own_spent = SlaCacheSpent.where(project_id: 1).order(:id).first
    foreign_spent = SlaCacheSpent.where(project_id: 2).order(:id).first

    endpoints = [
      [:patch, "/sla/caches/#{foreign_cache.id}/refresh"],
      [:patch, "/projects/#{STD}/sla/caches/#{foreign_cache.id}/refresh"],
      [:patch, "/projects/#{TMA}/sla/caches/#{foreign_cache.id}/refresh"],
      [:patch, '/sla/caches/refresh', {ids: [own_cache.id, foreign_cache.id]}],
      [:delete, "/sla/caches/#{foreign_cache.id}"],
      [:delete, "/projects/#{TMA}/sla/caches/#{foreign_cache.id}"],
      [:delete, '/sla/caches', {ids: [own_cache.id, foreign_cache.id]}],
      [:patch, "/projects/#{STD}/sla/caches/purge"],
      [:patch, '/sla/caches/purge'],
      [:patch, "/sla/cache_spents/#{foreign_spent.id}/refresh"],
      [:patch, '/sla/cache_spents/refresh', {ids: [own_spent.id, foreign_spent.id]}],
      [:delete, "/sla/cache_spents/#{foreign_spent.id}"],
      [:delete, '/sla/cache_spents', {ids: [own_spent.id, foreign_spent.id]}],
      [:patch, '/sla/cache_spents/purge']
    ]
    each_request(endpoints) do |verb, path, params|
      assert_api_denied verb, path, params, headers, [403, 404]
    end

    # Positive counterpart: the same restricted manager changes its own project.
    delete "/sla/caches/#{own_cache.id}.json", headers: headers
    assert_response :success
    assert_not SlaCache.exists?(own_cache.id)
    assert SlaCache.exists?(foreign_cache.id)
  end

  # List filtering

  test 'global cache lists only contain rows of the projects the user can view' do
    assert_operator SlaCache.where.not(project_id: DEVELOPER_PROJECT_IDS).count, :>, 0
    assert_operator SlaCacheSpent.where.not(project_id: DEVELOPER_PROJECT_IDS).count, :>, 0
    {
      'sla_caches' => ['sla_cache', SlaCache],
      'sla_cache_spents' => ['sla_cache_spent', SlaCacheSpent]
    }.each do |collection, (item, model)|
      expected_ids = model.where(project_id: DEVELOPER_PROJECT_IDS).order(:id).pluck(:id)
      assert_not_empty expected_ids
      FORMATS.each do |format|
        get "/sla/#{collection.delete_prefix('sla_')}.#{format}", params: ALL_STATUSES.merge(limit: 100),
          headers: api_key_headers('developer')
        assert_response :success
        total_count, items = index_payload(collection, item)
        assert_equal expected_ids.size, total_count, "#{collection}.#{format} total_count"
        assert_equal expected_ids, items.map { |row| row['id'].to_i }.sort, "#{collection}.#{format} items"
      end
    end
  end

  test 'global SLA definition lists only contain definitions of viewable projects' do
    sla_ids = SlaProjectTracker.where(project_id: DEVELOPER_PROJECT_IDS).distinct.order(:sla_id).pluck(:sla_id)
    level_ids = SlaLevel.where(sla_id: sla_ids).order(:id).pluck(:id)
    calendar_ids = SlaLevel.where(sla_id: sla_ids).distinct.order(:sla_calendar_id).pluck(:sla_calendar_id)
    assert_operator Sla.count, :>, sla_ids.size
    assert_operator SlaLevel.count, :>, level_ids.size
    assert_operator SlaCalendar.count, :>, calendar_ids.size
    {
      'slas' => ['sla', sla_ids],
      'levels' => ['sla_level', level_ids],
      'calendars' => ['sla_calendar', calendar_ids]
    }.each do |path, (item, expected_ids)|
      collection = path == 'slas' ? 'slas' : "sla_#{path}"
      FORMATS.each do |format|
        get "/sla/#{path}.#{format}", headers: api_key_headers('developer')
        assert_response :success, "#{path}.#{format}"
        total_count, items = index_payload(collection, item)
        assert_equal expected_ids.size, total_count, "#{path}.#{format} total_count"
        assert_equal expected_ids, items.map { |row| row['id'].to_i }.sort, "#{path}.#{format} items"
      end
    end
  end

  test 'global project tracker list only contains managed projects' do
    restrict_manager_to_project_1
    expected_ids = SlaProjectTracker.where(project_id: 1).order(:id).pluck(:id)
    assert_not_empty expected_ids
    assert_operator SlaProjectTracker.count, :>, expected_ids.size
    FORMATS.each do |format|
      get "/sla/project_trackers.#{format}", headers: api_key_headers('manager')
      assert_response :success
      total_count, items = index_payload('sla_project_trackers', 'sla_project_tracker')
      assert_equal expected_ids.size, total_count
      assert_equal expected_ids, items.map { |row| row['id'].to_i }.sort
    end
  end

  test 'global lists drop definitions and assignments of a project without the SLA module' do
    sla_ids = SlaProjectTracker.where(project_id: 4).distinct.order(:sla_id).pluck(:sla_id)
    level_ids = SlaLevel.where(sla_id: sla_ids).order(:id).pluck(:id)
    calendar_ids = SlaLevel.where(sla_id: sla_ids).distinct.order(:sla_calendar_id).pluck(:sla_calendar_id)
    link_ids = SlaProjectTracker.where(project_id: [2, 3, 4]).order(:id).pluck(:id)
    # Project 1 must own definitions and links that only its module exposes.
    assert_operator SlaProjectTracker.where(project_id: DEVELOPER_PROJECT_IDS).distinct.count(:sla_id), :>, sla_ids.size
    assert_operator SlaLevel.joins(sla: :sla_project_trackers).
      where(sla_project_trackers: {project_id: DEVELOPER_PROJECT_IDS}).distinct.count, :>, level_ids.size
    assert SlaProjectTracker.where(project_id: 1).exists?

    EnabledModule.where(project_id: 1, name: 'sla').delete_all
    FORMATS.each do |format|
      developer = api_key_headers('developer')
      assert_index_ids "/sla/slas.#{format}", {}, developer, 'slas', 'sla', sla_ids
      assert_index_ids "/sla/levels.#{format}", {}, developer, 'sla_levels', 'sla_level', level_ids
      assert_index_ids "/sla/calendars.#{format}", {}, developer, 'sla_calendars', 'sla_calendar', calendar_ids
      assert_index_ids "/sla/project_trackers.#{format}", {}, api_key_headers('manager'),
        'sla_project_trackers', 'sla_project_tracker', link_ids
    end
  end

  test 'a query filter on a foreign project or issue does not reveal its cache rows' do
    {
      'caches' => ['sla_caches', 'sla_cache', SlaCache],
      'cache_spents' => ['sla_cache_spents', 'sla_cache_spent', SlaCacheSpent]
    }.each do |path, (collection, item, model)|
      foreign = model.where(project_id: 2).order(:id).first
      assert foreign, "project 2 needs #{collection}"
      foreign_project_ids = model.where(project_id: 2).order(:id).pluck(:id)
      foreign_issue_ids = model.where(issue_id: foreign.issue_id).order(:id).pluck(:id)
      own_ids = model.where(project_id: 4).order(:id).pluck(:id)
      assert_not_empty own_ids
      FORMATS.each do |format|
        url = "/sla/#{path}.#{format}"
        assert_index_ids url, cache_filter('project_id', 2), api_key_headers('developer'), collection, item, []
        assert_index_ids url, cache_filter('issue_id', foreign.issue_id), api_key_headers('developer'), collection, item, []
        # Positive counterparts: the same filters select rows the user may see.
        assert_index_ids url, cache_filter('project_id', 4), api_key_headers('developer'), collection, item, own_ids
        assert_index_ids url, cache_filter('project_id', 2), api_key_headers('admin'), collection, item, foreign_project_ids
        assert_index_ids url, cache_filter('issue_id', foreign.issue_id), api_key_headers('admin'), collection, item,
          foreign_issue_ids
      end
    end
  end

  test 'paginated cache lists count and page through viewable rows only' do
    %w[sla_caches sla_cache_spents].each do |collection|
      model = collection.classify.constantize
      expected_count = model.where(project_id: DEVELOPER_PROJECT_IDS).count
      assert_operator expected_count, :>, 1
      assert_operator model.count, :>, expected_count
      FORMATS.each do |format|
        path = "/sla/#{collection.delete_prefix('sla_')}.#{format}"
        # An offset counted on unfiltered rows would return a foreign row here.
        get path, params: ALL_STATUSES.merge(limit: 1, offset: expected_count - 1), headers: api_key_headers('developer')
        assert_response :success
        total_count, items = index_payload(collection, collection.singularize)
        assert_equal expected_count, total_count, "#{path} total_count"
        assert_equal 1, items.size, "#{path} last page"
        assert_includes DEVELOPER_PROJECT_IDS, items.first['project_id'].to_i

        get path, params: ALL_STATUSES.merge(limit: 1, offset: expected_count), headers: api_key_headers('developer')
        assert_response :success
        total_count, items = index_payload(collection, collection.singularize)
        assert_equal expected_count, total_count
        assert_empty items, "#{path} beyond the last viewable row"
      end
    end
  end

  test 'caches of an issue the user cannot see are hidden from reads and writes' do
    cache = cache_with_spents(1)
    spent_ids = cache.sla_cache_spents.order(:id).pluck(:id)
    developer = api_key_headers('developer')
    get "/sla/caches/#{cache.id}.json", headers: developer
    assert_response :success, 'the cache is readable while its issue is visible'

    # Neither author nor assignee: a private issue is hidden by the default visibility.
    cache.issue.update_columns(is_private: true, assigned_to_id: nil)
    assert_not cache.issue.reload.visible?(User.find_by_login!('developer'))
    each_request([
      [:get, "/sla/caches/#{cache.id}"],
      [:get, "/projects/#{TMA}/sla/caches/#{cache.id}"],
      [:get, "/sla/cache_spents/#{spent_ids.first}"]
    ]) do |verb, path, params|
      assert_api_denied verb, path, params, developer, [403, 404]
    end
    expected_cache_ids = SlaCache.where(project_id: DEVELOPER_PROJECT_IDS).where.not(id: cache.id).order(:id).pluck(:id)
    expected_spent_ids = SlaCacheSpent.where(project_id: DEVELOPER_PROJECT_IDS).where.not(id: spent_ids).order(:id).pluck(:id)
    FORMATS.each do |format|
      params = ALL_STATUSES.merge(limit: 100)
      assert_index_ids "/sla/caches.#{format}", params, developer, 'sla_caches', 'sla_cache', expected_cache_ids
      assert_index_ids "/projects/#{TMA}/sla/caches.#{format}", params, developer, 'sla_caches', 'sla_cache',
        expected_cache_ids & SlaCache.where(project_id: 1).pluck(:id)
      assert_index_ids "/sla/cache_spents.#{format}", params, developer, 'sla_cache_spents', 'sla_cache_spent',
        expected_spent_ids
    end

    # Positive counterpart: a manager seeing all issues still reads the cache.
    manager = api_key_headers('manager')
    get "/sla/caches/#{cache.id}.xml", headers: manager
    assert_response :success
    assert_sla_payload

    # With the default visibility the manager can no longer change it either.
    Role.find(1).update!(issues_visibility: 'default')
    each_request([
      [:patch, "/sla/caches/#{cache.id}/refresh"],
      [:delete, "/sla/caches/#{cache.id}"],
      [:delete, "/projects/#{TMA}/sla/caches/#{cache.id}"],
      [:patch, "/sla/cache_spents/#{spent_ids.first}/refresh"],
      [:delete, "/sla/cache_spents/#{spent_ids.first}"]
    ]) do |verb, path, params|
      assert_api_denied verb, path, params, manager, [403, 404]
    end
  end

  test 'builtin roles of a public project only get the SLA permissions they hold' do
    Project.find(1).update_column(:is_public, true)
    project_cache_ids = SlaCache.where(project_id: 1).order(:id).pluck(:id)
    assert_not_empty project_cache_ids
    other = api_key_headers('other')
    Role.non_member.update!(permissions: [:view_issues, :view_sla])

    FORMATS.each do |format|
      assert_index_ids "/sla/caches.#{format}", ALL_STATUSES.merge(limit: 100), other, 'sla_caches', 'sla_cache',
        project_cache_ids
    end
    each_request(project_read_endpoints(TMA, 1)) do |verb, path, params|
      send(verb, path, params: params, headers: other)
      assert_response :success, "#{verb.upcase} #{path} as non member"
      assert_sla_payload
    end
    # view_sla through the non member role grants neither writes nor other projects.
    endpoints = project_write_endpoints(TMA, 1) + project_read_endpoints(STD, 2) + admin_read_endpoints
    each_request(endpoints) do |verb, path, params|
      assert_api_denied verb, path, params, other, [403]
    end

    with_settings login_required: '0' do
      each_request(project_read_endpoints(TMA, 1)) do |verb, path, params|
        assert_api_denied verb, path, params, {}, [401]
      end
      Role.anonymous.update!(permissions: [:view_issues, :view_sla])
      each_request(project_read_endpoints(TMA, 1)) do |verb, path, params|
        send(verb, path, params: params)
        assert_response :success, "#{verb.upcase} #{path} as anonymous"
        assert_sla_payload
      end
      each_request(project_write_endpoints(TMA, 1) + project_read_endpoints(STD, 2)) do |verb, path, params|
        assert_api_denied verb, path, params, {}, [401]
      end
    end
  end

  # Administration-only resources without a dedicated API test file

  test 'calendar holidays and level terms API is reserved to administrators' do
    calendar_holiday = SlaCalendarHoliday.order(:id).first
    level_term = SlaLevelTerm.order(:id).first
    holiday = SlaHoliday.where.not(id: SlaCalendarHoliday.where(sla_calendar_id: 1).select(:sla_holiday_id)).first ||
      SlaHoliday.generate!
    headers = api_key_headers('admin')

    FORMATS.each do |format|
      %W[/sla/calendar_holidays /sla/calendar_holidays/#{calendar_holiday.id}
         /sla/level_terms /sla/level_terms/#{level_term.id}].each do |path|
        get "#{path}.#{format}", headers: headers
        assert_response :success, path
        assert_sla_payload
      end
    end

    assert_difference 'SlaCalendarHoliday.count', 1 do
      post '/sla/calendar_holidays.json', headers: headers,
        params: {sla_calendar_holiday: {sla_calendar_id: 1, sla_holiday_id: holiday.id, match: true}}
    end
    assert_response :created
    created = SlaCalendarHoliday.order(:id).last
    put "/sla/calendar_holidays/#{created.id}.json", headers: headers,
      params: {sla_calendar_holiday: {match: false}}
    assert_response :success
    assert_equal false, created.reload.match
    assert_difference 'SlaCalendarHoliday.count', -1 do
      delete "/sla/calendar_holidays/#{created.id}.json", headers: headers
    end
    assert_response :success
    assert_difference 'SlaLevelTerm.count', -1 do
      delete "/sla/level_terms/#{level_term.id}.xml", headers: headers
    end
    assert_response :success
  end

  private

  # Yields each endpoint in both formats; the format is appended to the path.
  def each_request(endpoints)
    endpoints.each do |verb, path, params|
      FORMATS.each { |format| yield verb, "#{path}.#{format}", params }
    end
  end

  def api_key_headers(login)
    {'X-Redmine-API-Key' => User.find_by_login!(login).api_key}
  end

  def assert_api_denied(verb, path, params, headers, statuses)
    before = sla_database_state
    send(verb, path, params: params, headers: headers)
    label = "#{verb.upcase} #{path} as #{headers.values.first || 'anonymous'}"
    assert_includes statuses, response.status, "#{label}: unexpected status #{response.status}"
    assert_no_match(/"id"|<id>|total_count/, response.body, "#{label}: response leaks SLA data")
    assert_equal before, sla_database_state, "#{label}: denied request changed SLA data"
  end

  # The allowed responses must carry record data, so the denied ones are
  # compared against a body that really can contain it.
  def assert_sla_payload
    assert_match(/"id"|<id>/, response.body)
  end

  def sla_database_state
    SLA_MODELS.to_h { |model| [model.name, model.order(:id).pluck(*model.column_names)] }
  end

  # Returns [total_count, items as string hashes] for both API formats.
  def index_payload(collection, item)
    if response.media_type == 'application/json'
      body = response.parsed_body
      [body.fetch('total_count'), body.fetch(collection).map { |row| row.transform_values(&:to_s) }]
    else
      root = Nokogiri::XML(response.body).at_xpath("/#{collection}")
      assert root, "missing #{collection} root element"
      items = root.xpath(item).map { |node| node.element_children.to_h { |child| [child.name, child.text] } }
      [root['total_count'].to_i, items]
    end
  end

  def assert_index_ids(path, params, headers, collection, item, expected_ids)
    get path, params: params, headers: headers
    assert_response :success, path
    total_count, items = index_payload(collection, item)
    assert_equal expected_ids.size, total_count, "#{path} total_count"
    assert_equal expected_ids.sort, items.map { |row| row['id'].to_i }.sort, "#{path} items"
  end

  # Explicit filters replace the short ones, so the status filter is repeated.
  def cache_filter(field, value)
    {f: ['issue.status_id', field], op: {'issue.status_id' => '*', field => '='},
     v: {field => [value.to_s]}, limit: 100}
  end

  def cache_with_spents(project_id)
    SlaCache.where(project_id: project_id).joins(:sla_cache_spents).distinct.order(:id).first.tap do |cache|
      assert cache, "project #{project_id} needs a cache with spent rows"
    end
  end

  def restrict_manager_to_project_1
    Member.where(user_id: 2).where.not(project_id: 1).destroy_all
  end

  def project_read_endpoints(identifier, project_id)
    cache = SlaCache.where(project_id: project_id).order(:id).first
    spent = SlaCacheSpent.where(project_id: project_id).order(:id).first
    link = SlaProjectTracker.where(project_id: project_id).order(:id).first
    endpoints = [
      [:get, "/projects/#{identifier}/sla/slas"],
      [:get, "/projects/#{identifier}/sla/levels"],
      [:get, "/projects/#{identifier}/sla/calendars"],
      [:get, "/projects/#{identifier}/sla/caches", ALL_STATUSES],
      [:get, '/sla/caches', ALL_STATUSES.merge(project_id: project_id)],
      [:get, '/sla/cache_spents', ALL_STATUSES.merge(project_id: project_id)]
    ]
    if link
      endpoints += [
        [:get, "/projects/#{identifier}/sla/slas/#{link.sla_id}"],
        [:get, "/projects/#{identifier}/sla/levels/#{SlaLevel.find_by!(sla_id: link.sla_id).id}"]
      ]
    end
    endpoints << [:get, "/projects/#{identifier}/sla/caches/#{cache.id}"] if cache
    endpoints << [:get, "/sla/caches/#{cache.id}"] if cache
    endpoints << [:get, "/sla/cache_spents/#{spent.id}"] if spent
    endpoints
  end

  def admin_read_endpoints
    %w[types statuses holidays schedules calendar_holidays level_terms].flat_map do |path|
      model = "Sla#{path.singularize.camelize}".constantize
      [[:get, "/sla/#{path}"], [:get, "/sla/#{path}/#{model.order(:id).first.id}"]]
    end
  end

  def read_endpoints
    project_read_endpoints(TMA, 1) + admin_read_endpoints + [
      [:get, '/sla/slas'], [:get, '/sla/slas/1'],
      [:get, '/sla/levels'], [:get, '/sla/levels/1'],
      [:get, '/sla/calendars'], [:get, '/sla/calendars/1'],
      [:get, '/sla/caches', ALL_STATUSES], [:get, '/sla/cache_spents', ALL_STATUSES],
      [:get, '/sla/project_trackers'], [:get, "/projects/#{TMA}/sla/trackers"]
    ]
  end

  def admin_write_endpoints
    # Valid attributes, so a request that slipped through would really write.
    holiday_outside_calendars = SlaHoliday.generate!
    {
      'slas' => [Sla, {name: 'Isolation SLA'}],
      'types' => [SlaType, {name: 'Isolation type'}],
      'statuses' => [SlaStatus, {sla_type_id: SlaType.order(:id).last.id, status_id: IssueStatus.order(:id).last.id}],
      'holidays' => [SlaHoliday, {name: 'Isolation holiday', date: '2099-12-31'}],
      'calendars' => [SlaCalendar, {name: 'Isolation calendar'}],
      'schedules' => [SlaSchedule, {sla_calendar_id: 1, dow: 0, start_time: '01:00', end_time: '02:00', match: true}],
      'levels' => [SlaLevel, {name: 'Isolation level', sla_id: 1, sla_calendar_id: SlaCalendar.order(:id).last.id}],
      'calendar_holidays' => [SlaCalendarHoliday, {sla_calendar_id: 2, sla_holiday_id: holiday_outside_calendars.id, match: true}]
    }.flat_map do |path, (model, attributes)|
      key = model.model_name.param_key
      id = model.order(:id).first.id
      [
        [:post, "/sla/#{path}", {key => attributes}],
        [:put, "/sla/#{path}/#{id}", {key => attributes}],
        [:delete, "/sla/#{path}/#{id}"],
        [:delete, "/sla/#{path}", {ids: [id]}]
      ]
    end + [
      [:delete, "/sla/level_terms/#{SlaLevelTerm.order(:id).first.id}"]
    ]
  end

  def global_cache_write_endpoints
    [[:patch, '/sla/caches/purge'], [:patch, '/sla/cache_spents/purge']]
  end

  def project_write_endpoints(identifier, project_id)
    cache = cache_with_spents(project_id)
    spent = SlaCacheSpent.where(project_id: project_id).order(:id).first
    link = SlaProjectTracker.where(project_id: project_id).order(:id).first
    new_link = {sla_project_tracker: {project_id: project_id, tracker_id: 2, sla_id: 1}}
    [
      [:patch, "/sla/caches/#{cache.id}/refresh"],
      [:patch, "/projects/#{identifier}/sla/caches/#{cache.id}/refresh"],
      [:patch, '/sla/caches/refresh', {ids: [cache.id]}],
      [:delete, "/sla/caches/#{cache.id}"],
      [:delete, "/projects/#{identifier}/sla/caches/#{cache.id}"],
      [:delete, '/sla/caches', {ids: [cache.id]}],
      [:patch, "/projects/#{identifier}/sla/caches/purge"],
      [:patch, "/sla/cache_spents/#{spent.id}/refresh"],
      [:patch, '/sla/cache_spents/refresh', {ids: [spent.id]}],
      [:delete, "/sla/cache_spents/#{spent.id}"],
      [:delete, '/sla/cache_spents', {ids: [spent.id]}],
      [:post, '/sla/project_trackers', new_link],
      [:post, "/projects/#{identifier}/sla/trackers", new_link],
      [:put, "/sla/project_trackers/#{link.id}", {sla_project_tracker: {sla_id: 2}}],
      [:put, "/projects/#{identifier}/sla/trackers/#{link.id}", {sla_project_tracker: {sla_id: 2}}],
      [:delete, "/sla/project_trackers/#{link.id}"],
      [:delete, "/projects/#{identifier}/sla/trackers/#{link.id}"],
      [:delete, '/sla/project_trackers', {ids: [link.id]}]
    ]
  end
end
