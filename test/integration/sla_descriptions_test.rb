# frozen_string_literal: true
# File: redmine_sla/test/integration/sla_descriptions_test.rb
# SPDX-License-Identifier: GPL-2.0-or-later

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

require_relative "../application_sla_integration_test_case"

# Descriptions of the named SLA objects are shown as tooltips wherever their
# names are displayed (issues first), and exposed through the forms and API.
# Fixtures: SLA 1, type GTI, calendar 1 and level 1 have a description;
# type GTR has none.
class SlaDescriptionsTest < ApplicationSlaIntegrationTestCase

  def setup
    User.current = nil
    set_language_if_valid 'en'
  end

  # Issue page and issue list

  test "issue SLA block shows level, calendar and type descriptions as tooltips" do
    sla_level = SlaLevel.find(1)
    issue = described_issue
    log_user('admin', 'admin')

    get "/issues/#{issue.id}"
    assert_response :success

    assert_select 'div.sla.attribute' do
      assert_select "a[href='/sla/levels/#{sla_level.id}'][title=?]", sla_level.description
      assert_select "a[href='/sla/calendars/#{sla_level.sla_calendar_id}'][title=?]", sla_level.sla_calendar.description
      assert_select 'strong span[title=?]', SlaType.find(1).description, :text => 'GTI'
    end
  end

  test "issue SLA block keeps the generic tooltip without description" do
    issue = described_issue
    SlaLevel.find(1).update_column(:description, nil)
    log_user('admin', 'admin')

    get "/issues/#{issue.id}"
    assert_response :success
    assert_select "div.sla.attribute a[href='/sla/levels/1'][title=?]", "Show : SLA Level"
  end

  test "issue list SLA level column shows the level description as tooltip" do
    issue = described_issue
    log_user('admin', 'admin')

    get "/projects/#{issue.project.identifier}/issues",
      :params => {:set_filter => 1, :f => ['status_id'], :op => {'status_id' => '*'}, :c => ['subject', 'get_sla_level']}
    assert_response :success
    assert_select "tr#issue-#{issue.id} td.get_sla_level a[title=?]", SlaLevel.find(1).description
  end

  # Plugin lists and pages

  test "SLA type list shows a tooltip only on described names" do
    log_user('admin', 'admin')

    get "/sla/types"
    assert_response :success
    assert_select "tr#entity_id_1 td.name span[title=?]", SlaType.find(1).description, :text => 'GTI'
    assert_select "tr#entity_id_2 td.name span[title]", 0
  end

  test "SLA level page shows its description" do
    log_user('admin', 'admin')

    get "/sla/levels/1"
    assert_response :success
    assert_select 'div.sla-description', :text => /#{Regexp.escape(SlaLevel.find(1).description)}/
  end

  # Exercise the same description contract on all four resource controllers.
  DESCRIBED_RESOURCES = {
    'slas' => [Sla, 'sla'],
    'types' => [SlaType, 'sla_type'],
    'calendars' => [SlaCalendar, 'sla_calendar'],
    'levels' => [SlaLevel, 'sla_level']
  }.freeze

  DESCRIBED_RESOURCES.each do |resource, (model_class, parameter_name)|
    test "#{resource} description is created updated and cleared through HTML" do
      log_user('admin', 'admin')
      get "/sla/#{resource}/new"
      assert_response :success
      assert_select "textarea##{parameter_name}_description.wiki-edit"

      attributes = creation_attributes(model_class, "Description form #{resource}")
      attributes[:description] = '**First answer** & support'
      post "/sla/#{resource}", :params => {parameter_name => attributes}
      assert_response :redirect
      record = model_class.find_by!(name: attributes[:name])
      assert_equal attributes[:description], record.description

      get "/sla/#{resource}/#{record.id}/edit"
      assert_response :success
      assert_select "textarea##{parameter_name}_description", :text => attributes[:description]

      patch "/sla/#{resource}/#{record.id}", :params => {parameter_name => {:description => 'Updated description'}}
      assert_response :redirect
      assert_equal 'Updated description', record.reload.description

      patch "/sla/#{resource}/#{record.id}", :params => {parameter_name => {:description => ''}}
      assert_response :redirect
      assert_equal '', record.reload.description
      get "/sla/#{resource}/#{record.id}"
      assert_response :success
      assert_select 'div.sla-description', 0
    end

    test "#{resource} API creates updates clears and exposes source descriptions" do
      with_settings :rest_api_enabled => '1' do
        attributes = creation_attributes(model_class, "Description API #{resource}")
        attributes[:description] = '**Answer** & support'
        post "/sla/#{resource}.json", :params => {parameter_name => attributes}, :headers => credentials('admin')
        assert_response :created
        record = model_class.find_by!(name: attributes[:name])
        assert_equal attributes[:description], record.description

        get "/sla/#{resource}/#{record.id}.json", :headers => credentials('admin')
        assert_response :success
        assert_equal attributes[:description], ActiveSupport::JSON.decode(response.body)[parameter_name]['description']
        get "/sla/#{resource}.json", :params => {:limit => 100}, :headers => credentials('admin')
        assert_response :success
        records = ActiveSupport::JSON.decode(response.body)[model_class.table_name]
        assert records.all? { |entry| entry.key?('description') }
        assert_equal attributes[:description], records.find { |entry| entry['id'] == record.id }['description']

        get "/sla/#{resource}/#{record.id}.xml", :headers => credentials('admin')
        assert_response :success
        assert_select "#{parameter_name} description", :text => attributes[:description]
        get "/sla/#{resource}.xml", :params => {:limit => 100}, :headers => credentials('admin')
        assert_response :success
        assert_select "#{model_class.table_name} #{parameter_name} description", :text => attributes[:description]

        patch "/sla/#{resource}/#{record.id}.json", :params => {parameter_name => {:description => '*Updated*'}}, :headers => credentials('admin')
        assert_response :success
        assert_equal '*Updated*', record.reload.description
        patch "/sla/#{resource}/#{record.id}.json", :params => {parameter_name => {:description => ''}}, :headers => credentials('admin')
        assert_response :success
        assert_equal '', record.reload.description
      end
    end

    test "#{resource} rejects description writes from a non administrator in HTML and API" do
      record = model_class.find(1)
      original_description = record.description
      log_user('developer', 'developer')
      patch "/sla/#{resource}/1", :params => {parameter_name => {:description => 'Forbidden change'}}
      assert_response :forbidden
      assert_equal original_description, record.reload.description
      with_settings :rest_api_enabled => '1' do
        patch "/sla/#{resource}/1.json", :params => {parameter_name => {:description => 'Forbidden change'}}, :headers => credentials('developer')
        assert_response :forbidden
        assert_equal original_description, record.reload.description
      end
    end

    test "#{resource} description pages render wiki text and escape script content" do
      record = model_class.find(1)
      with_settings :text_formatting => 'common_mark' do
        record.update!(description: '**Answer** <script>alert(1)</script>')
        log_user('admin', 'admin')
        get "/sla/#{resource}/1"
        assert_response :success
        assert_select 'div.sla-description strong', :text => 'Answer'
        assert_select 'div.sla-description script', 0
      end
    end
  end

  {'slas' => [Sla, 3], 'calendars' => [SlaCalendar, 2], 'levels' => [SlaLevel, 3]}.each do |resource, (model_class, foreign_id)|
    test "project #{resource} descriptions respect HTML and API visibility" do
      foreign_record = model_class.find(foreign_id)
      foreign_record.update!(description: 'Confidential foreign description')
      log_user('developer', 'developer')
      project_path = "/projects/project-sla-tests-tma/sla/#{resource}"
      get "#{project_path}/1"
      assert_response :success
      assert_select 'div.sla-description', :text => /#{Regexp.escape(model_class.find(1).description)}/
      get project_path, :params => {:set_filter => 1, :c => ['name', 'description']}
      assert_response :success
      assert_not_includes response.body, foreign_record.description
      get "#{project_path}/#{foreign_id}"
      assert_response :forbidden
      assert_not_includes response.body, foreign_record.description
      get "/projects/project-sla-tests-std/sla/#{resource}/#{foreign_id}"
      assert_response :forbidden
      assert_not_includes response.body, foreign_record.description

      with_settings :rest_api_enabled => '1' do
        get "#{project_path}/1.json", :headers => credentials('developer')
        assert_response :success
        assert_equal model_class.find(1).description, ActiveSupport::JSON.decode(response.body)[model_class.model_name.param_key]['description']
        get "#{project_path}.json", :headers => credentials('developer')
        assert_response :success
        assert_not_includes response.body, foreign_record.description
        get "#{project_path}/#{foreign_id}.json", :headers => credentials('developer')
        assert_response :forbidden
        assert_not_includes response.body, foreign_record.description
        get "#{project_path}/1.json", :headers => credentials('reporter')
        assert_response :forbidden
        assert_not_includes response.body, model_class.find(1).description
      end
    end

    test "anonymous users cannot read project #{resource} descriptions" do
      get "/projects/project-sla-tests-tma/sla/#{resource}/1"
      assert_response :redirect
      assert_not_includes response.body, model_class.find(1).description
      with_settings :rest_api_enabled => '1' do
        get "/projects/project-sla-tests-tma/sla/#{resource}/1.json"
        assert_response :unauthorized
        assert_not_includes response.body, model_class.find(1).description
      end
    end
  end

  test "time entry list shows level tooltips and supports entries without an issue" do
    User.current = User.find(1)
    issue = described_issue
    activity = TimeEntryActivity.create!(name: 'Description activity', active: true)
    attributes = {:project => issue.project, :user => User.find(1), :activity => activity, :hours => 1, :spent_on => Date.today}
    described_entry = TimeEntry.create!(attributes.merge(:issue => issue))
    unrelated_entry = TimeEntry.create!(attributes)
    log_user('admin', 'admin')
    get "/projects/#{issue.project.identifier}/time_entries", :params => {:set_filter => 1, :f => ['spent_on'], :op => {'spent_on' => '*'}, :c => ['id', 'get_sla_level']}
    assert_response :success
    assert_select "tr#time-entry-#{described_entry.id} td.get_sla_level a[title=?]", SlaLevel.find(1).description
    assert_select "tr#time-entry-#{unrelated_entry.id} td.get_sla_level a", 0
  end

  private

  def creation_attributes(model_class, name)
    attributes = {:name => name}
    if model_class == SlaLevel
      attributes.merge!(:sla_id => Sla.create!(:name => "Parent #{name}").id, :sla_calendar_id => 1)
    end
    attributes
  end

  # An issue whose SLA level is the described level 1.
  def described_issue
    sla_cache = SlaCache.where(sla_level_id: 1).order(:issue_id).first
    assert sla_cache, "an issue on SLA level 1 is expected in the fixtures"
    sla_cache.issue
  end

end
