# frozen_string_literal: true

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

require_relative "../../test_helper"

class Redmine::ApiTest::SlaCalendarsTest < Redmine::ApiTest::Base
  include ActiveJob::TestHelper

  # SlaCalendar#index in XML

  test "GET /sla/calendars.xml should success for admin" do
    sla_calendar = SlaCalendar.order(:id).first
    sla_calendar_count = SlaCalendar.count
    ['admin'].each do |user|
      get "/sla/calendars.xml?sort=id",
        :headers=>credentials(user)
      assert_response :success
      assert_sla_calendars_index_xml(sla_calendar,sla_calendar_count)
    end
  end

  test "GET /sla/calendars.xml should forbidden for other users" do
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      get "/sla/calendars.xml",
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end

  test "GET /sla/calendars.xml should unauthorized withtout credentials" do
      get "/sla/calendars.xml"
      assert_response :unauthorized
  end    

  # SlaCalendar#index in JSON

  test "GET /sla/calendars.json should success for admin" do
    sla_calendar = SlaCalendar.order(:id).first
    sla_calendar_count = SlaCalendar.count
    ['admin'].each do |user|
      get "/sla/calendars.json?sort=id",
        :headers => credentials(user)
      assert_response :success
      assert_sla_calendars_index_json(sla_calendar,sla_calendar_count)
    end
  end

  test "GET /sla/calendars.json should forbidden for other users" do
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      get "/sla/calendars.json",
        :headers => credentials(user)
      assert_response :forbidden
    end
  end  

  test "GET /sla/calendars.json should unauthorized withtout credentials" do
      get "/sla/calendars.json"
      assert_response :unauthorized
  end   

  # SlaCalendar#show in XML

  test "GET /sla/calendars/:id.xml should success for admin" do
    sla_calendar = SlaCalendar.first
    ['admin','manager','developer','sysadmin'].each do |user|
      get "/sla/calendars/#{sla_calendar.id}.xml",
        :headers=>credentials(user)
      assert_response :success
      assert_sla_calendar_show_xml(sla_calendar)
    end
  end

  test "GET /sla/calendars/:id.xml should forbidden for other users" do
    sla_calendar = SlaCalendar.first
    ['reporter','other'].each do |user|
      get "/sla/calendars/#{sla_calendar.id}.xml",
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end

  test "GET /sla/calendars/:id.xml should unauthorized withtout credentials" do
    sla_calendar = SlaCalendar.first
    get "/sla/calendars/#{sla_calendar.id}.xml"
    assert_response :unauthorized
  end   

  # SlaCalendar#show in JSON

  test "GET /sla/calendars/:id.json should success for admin" do
    sla_calendar = SlaCalendar.first
    ['admin','manager','developer','sysadmin'].each do |user|
      get "/sla/calendars/#{sla_calendar.id}.json",
        :headers => credentials(user)
      assert_response :success
      assert_sla_calendar_show_json(sla_calendar)
    end
  end

  test "GET /sla/calendars/:id.json should forbidden for ohter users" do
    sla_calendar = SlaCalendar.first
    ['reporter','other'].each do |user|
      get "/sla/calendars/#{sla_calendar.id}.json",
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end
 
  test "GET /sla/calendars/:id.json should forbidden withtout credentials" do
    sla_calendar = SlaCalendar.first
    get "/sla/calendars/#{sla_calendar.id}.json"
    assert_response :unauthorized
  end  

  # SlaCalendar#create in XML

  test "POST /sla/calendars.xml with blank parameters should unprocessable_entity for admin" do
    assert_no_difference('SlaCalendar.count') do
      post "/sla/calendars.xml",
        :params => {:sla_calendar => {name: ''}},
        :headers => credentials('admin')
    end
    assert_response :unprocessable_entity
    assert_equal 'application/xml', @response.media_type
    assert_select 'errors error', :text => "Name cannot be blank"
  end

  test "POST /sla/calendars.xml with invalid parameters should unprocessable_entity for admin" do
    sla_calendar = SlaCalendar.first
    assert_no_difference('SlaCalendar.count') do
      post "/sla/calendars.xml",
        :params => {:sla_calendar => {name: sla_calendar.name}},
        :headers => credentials('admin')
    end
    assert_response :unprocessable_entity
    assert_equal 'application/xml', @response.media_type
    assert_select 'errors error', :text => "Name has already been taken"
  end

  test "POST /sla/calendars.xml with valid parameters should success for admin" do
    assert_difference('SlaCalendar.count',1) do
      post "/sla/calendars.xml",
      :params => {:sla_calendar => { name: 'API Test'} },
        :headers => credentials('admin')
    end
    assert_response :success
    assert_equal 'application/xml', @response.media_type
  end

  test "POST /sla/calendars.xml should forbidden for other users" do
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      post "/sla/calendars.xml",
        :params => {:sla_calendar => { :name => 'API Test' } },
        :headers => credentials(user)
      assert_response :forbidden
    end
  end
 
  test "POST /sla/calendars.xml should unauthorized withtout credentials" do
    post "/sla/calendars.xml",
      :params => {:sla_calendar => { name: 'API Test'} }
    assert_response :unauthorized
  end      

  # SlaCalendar#update in XML

  test "PUT /sla/calendars/:id.xml with blank parameters should unprocessable_entity for admin" do
    sla_calendar = SlaCalendar.first
    assert_no_difference('SlaCalendar.count') do
      put "/sla/calendars/#{sla_calendar.id}.xml",
        :params => {:sla_calendar => {name: ''}},
        :headers => credentials('admin')
    end
    assert_response :unprocessable_entity
    assert_equal 'application/xml', @response.media_type
    assert_select 'errors', :text => "Name cannot be blank"
  end

  test "PUT /sla/calendars/:id.xml with invalid parameters should unprocessable_entity for admin" do
    sla_calendar = SlaCalendar.first
    sla_calendar_last = SlaCalendar.last
    assert_no_difference('SlaCalendar.count') do
      put "/sla/calendars/#{sla_calendar.id}.xml",
        :params => {:sla_calendar => {name: sla_calendar_last.name}},
        :headers => credentials('admin')
    end
    assert_response :unprocessable_entity
    assert_equal 'application/xml', @response.media_type
    assert_select 'errors', :text => "Name has already been taken"
  end

  test "PUT /sla/calendars/:id.xml with valid parameters should update the sla_calendar" do
    sla_calendar = SlaCalendar.first
    assert_no_difference 'SlaCalendar.count' do
      put "/sla/calendars/#{sla_calendar.id}.xml",
        :params => {:sla_calendar => {name: 'API update'}},
        :headers => credentials('admin')
    end
    assert_response :no_content
    assert_equal '', @response.body
    assert_nil @response.media_type
    sla_calendar = SlaCalendar.find(sla_calendar.id)
    assert_equal 'API update', sla_calendar.name
  end

  test "PUT /sla/calendars/:id.xml should forbidden for other users" do
    sla_calendar = SlaCalendar.first
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      put "/sla/calendars/#{sla_calendar.id}.xml",
        :params => {:sla_calendar => {name: 'API Test'}},
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end
 
  test "PUT /sla/calendars/:id.xml should unauthorized withtout credentials" do
    sla_calendar = SlaCalendar.first
    put "/sla/calendars/#{sla_calendar.id}.xml",
      :params => {:sla_calendar => {name: 'API Test'}}
    assert_response :unauthorized
  end  

  # SlaCalendar#destroy in XML

  test "DELETE /sla/calendars/:id.xml should success for admin" do
    sla_calendar = SlaCalendar.generate!
    sla_calendar_id = sla_calendar.id
    assert_difference('SlaCalendar.count',-1) do
      delete "/sla/calendars/#{sla_calendar_id}.xml",
        :headers => credentials('admin')
    end
    assert_response :no_content
    assert_equal '', @response.body
    assert_nil SlaCalendar.find_by(id: sla_calendar_id)
  end

  test "DELETE /sla/calendars/:id.xml should forbidden for other users" do
    sla_calendar = SlaCalendar.generate!
    sla_calendar_id = sla_calendar.id
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      delete "/sla/calendars/#{sla_calendar_id}.xml",
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end
 
  test "DELETE /sla/calendars/:id.json should unauthorized withtout credentials" do
    sla_calendar = SlaCalendar.generate!
    sla_calendar_id = sla_calendar.id
    delete "/sla/calendars/#{sla_calendar_id}.xml"
    assert_response :unauthorized
  end    

  private

  def assert_sla_calendar_show_xml(sla_calendar)
    assert_equal 'application/xml', @response.media_type
    assert_select 'sla_calendar>id', :integer => sla_calendar.id
    assert_select 'sla_calendar>name', :text => sla_calendar.name
  end

  def assert_sla_calendars_index_xml(sla_calendar,sla_calendar_count)
    assert_equal 'application/xml', @response.media_type
    assert_select 'sla_calendars' do
      assert_select '[total_count=?]', sla_calendar_count
    end    
    assert_select 'sla_calendars>sla_calendar:first-child' do
      assert_select '>id', :integer => sla_calendar.id
      assert_select '>name', :text => sla_calendar.name
    end
  end

  def assert_sla_calendar_show_json(sla_calendar)
    assert_equal 'application/json', @response.media_type
    json = ActiveSupport::JSON.decode(response.body)
    assert_kind_of Hash, json
    assert_kind_of Hash, json['sla_calendar']
    assert_equal sla_calendar.id, json['sla_calendar']['id']
    assert_equal sla_calendar.name, json['sla_calendar']['name']
  end

  def assert_sla_calendars_index_json(sla_calendar,sla_calendar_count)
    assert_equal 'application/json', @response.media_type
    json = ActiveSupport::JSON.decode(response.body)
    assert_kind_of Hash, json
    assert_kind_of Array, json['sla_calendars']
    assert_kind_of Hash, json['sla_calendars'].first
    assert json['sla_calendars'].first.has_key?('id')
    assert json['sla_calendars'].first.has_key?('name')
    assert_equal(sla_calendar.id, json['sla_calendars'].first['id'])
    assert_equal(sla_calendar.name, json['sla_calendars'].first['name'])
    assert_equal(sla_calendar_count, json['total_count'])
  end


end