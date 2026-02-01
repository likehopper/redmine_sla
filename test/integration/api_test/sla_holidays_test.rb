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

require_relative "../../application_sla_api_test_case"

class Redmine::ApiTest::SlaHolidaysTest < ApplicationSlaApiTestCase
  include ActiveJob::TestHelper

  # SlaHoliday#index in XML

  test "GET /sla/holidays.xml should success for admin" do
    sla_holiday = SlaHoliday.order(:date).first
    sla_holiday_count = SlaHoliday.count
    ['admin'].each do |user|
      get "/sla/holidays.xml?sort=date",
        :headers=>credentials(user)
      assert_response :success
      assert_sla_holidays_index_xml(sla_holiday,sla_holiday_count)
    end
  end

  test "GET /sla/holidays.xml should forbidden for other users" do
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      get "/sla/holidays.xml",
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end

  test "GET /sla/holidays.xml should unauthorized withtout credentials" do
      get "/sla/holidays.xml"
      assert_response :unauthorized
  end    

  # SlaHoliday#index in JSON

  test "GET /sla/holidays.json should success for admin" do
    sla_holiday = SlaHoliday.order(:date).first
    sla_holiday_count = SlaHoliday.count
    ['admin'].each do |user|
      get "/sla/holidays.json?sort=date",
        :headers => credentials(user)
      assert_response :success
      assert_sla_holidays_index_json(sla_holiday,sla_holiday_count)
    end
  end

  test "GET /sla/holidays.json should forbidden for other users" do
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      get "/sla/holidays.json",
        :headers => credentials(user)
      assert_response :forbidden
    end
  end  

  test "GET /sla/holidays.json should unauthorized withtout credentials" do
      get "/sla/holidays.json"
      assert_response :unauthorized
  end   

  # SlaHoliday#show in XML

  test "GET /sla/holidays/:id.xml should success for admin" do
    sla_holiday = SlaHoliday.first
    ['admin'].each do |user|
      get "/sla/holidays/#{sla_holiday.id}.xml",
        :headers=>credentials(user)
      assert_response :success
      assert_sla_holiday_show_xml(sla_holiday)
    end
  end

  test "GET /sla/holidays/:id.xml should forbidden for other users" do
    sla_holiday = SlaHoliday.first
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      get "/sla/holidays/#{sla_holiday.id}.xml",
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end

  test "GET /sla/holidays/:id.xml should unauthorized withtout credentials" do
    sla_holiday = SlaHoliday.first
    get "/sla/holidays/#{sla_holiday.id}.xml"
    assert_response :unauthorized
  end   

  # SlaHoliday#show in JSON

  test "GET /sla/holidays/:id.json should success for admin" do
    sla_holiday = SlaHoliday.first
    ['admin'].each do |user|
      get "/sla/holidays/#{sla_holiday.id}.json",
        :headers => credentials(user)
      assert_response :success
      assert_sla_holiday_show_json(sla_holiday)
    end
  end

  test "GET /sla/holidays/:id.json should forbidden for ohter users" do
    sla_holiday = SlaHoliday.first
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      get "/sla/holidays/#{sla_holiday.id}.json",
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end
 
  test "GET /sla/holidays/:id.json should forbidden withtout credentials" do
    sla_holiday = SlaHoliday.first
    get "/sla/holidays/#{sla_holiday.id}.json"
    assert_response :unauthorized
  end  

  # SlaHoliday#create in XML

  test "POST /sla/holidays.xml with blank parameters should unprocessable_entity for admin" do
    assert_no_difference('SlaHoliday.count') do
      post "/sla/holidays.xml",
        :params => {:sla_holiday => { name: 'API Test'}},
        :headers => credentials('admin')
    end
    assert_response :unprocessable_entity
    assert_equal 'application/xml', @response.media_type
    assert_select 'errors error', :text => "Date cannot be blank"    
    assert_no_difference('SlaHoliday.count') do
      post "/sla/holidays.xml",
        :params => {:sla_holiday => {date: Date.new(2000, 1, 1), name: ''}},
        :headers => credentials('admin')
    end
    assert_response :unprocessable_entity
    assert_equal 'application/xml', @response.media_type
    assert_select 'errors error', :text => "Name cannot be blank"
  end

  test "POST /sla/holidays.xml with invalid parameters should unprocessable_entity for admin" do
    sla_holiday = SlaHoliday.first
    assert_no_difference('SlaHoliday.count') do
      post "/sla/holidays.xml",
        :params => {:sla_holiday => {date: sla_holiday.date, name: sla_holiday.name}},
        :headers => credentials('admin')
    end
    assert_response :unprocessable_entity
    assert_equal 'application/xml', @response.media_type
    assert_select 'errors error', :text => "Date has already been taken"
  end

  test "POST /sla/holidays.xml with valid parameters should success for admin" do
    assert_difference('SlaHoliday.count',1) do
      post "/sla/holidays.xml",
      :params => {:sla_holiday => { date: Date.new(2000, 1, 1), name: 'API Test'} },
        :headers => credentials('admin')
    end
    assert_response :success
    assert_equal 'application/xml', @response.media_type
  end

  test "POST /sla/holidays.xml should forbidden for other users" do
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      post "/sla/holidays.xml",
        :params => {:sla_holiday => { :date => Date.new(2000,1,1), :name => 'API Test' }},
        :headers => credentials(user)
      assert_response :forbidden
    end
  end
 
  test "POST /sla/holidays.xml should unauthorized withtout credentials" do
    post "/sla/holidays.xml",
      :params => {:sla_holiday => {date: Date.new(2000, 1, 1), name: 'API Test'}}
    assert_response :unauthorized
  end      

  # SlaHoliday#update in XML

  test "PUT /sla/holidays/:id.xml with blank parameters should unprocessable_entity for admin" do
    sla_holiday = SlaHoliday.first
    assert_no_difference('SlaHoliday.count') do
      put "/sla/holidays/#{sla_holiday.id}.xml",
        :params => {:sla_holiday => {name: ''}},
        :headers => credentials('admin')
    end
    assert_response :unprocessable_entity
    assert_equal 'application/xml', @response.media_type
    assert_select 'errors', :text => "Name cannot be blank"
  end

  test "PUT /sla/holidays/:id.xml with invalid parameters should unprocessable_entity for admin" do
    sla_holiday = SlaHoliday.first
    sla_holiday_last = SlaHoliday.last
    assert_no_difference('SlaHoliday.count') do
      put "/sla/holidays/#{sla_holiday.id}.xml",
        :params => {:sla_holiday => {date: sla_holiday_last.date}},
        :headers => credentials('admin')
    end
    assert_response :unprocessable_entity
    assert_equal 'application/xml', @response.media_type
    assert_select 'errors', :text => "Date has already been taken"
  end

  test "PUT /sla/holidays/:id.xml with valid parameters should update the sla_holiday" do
    sla_holiday = SlaHoliday.first
    assert_no_difference 'SlaHoliday.count' do
      put "/sla/holidays/#{sla_holiday.id}.xml",
        :params => {:sla_holiday => {name: 'API update'}},
        :headers => credentials('admin')
    end
    assert_response :no_content
    assert_equal '', @response.body
    assert_nil @response.media_type
    sla_holiday = SlaHoliday.find(sla_holiday.id)
    assert_equal 'API update', sla_holiday.name
  end

  test "PUT /sla/holidays/:id.xml should forbidden for other users" do
    sla_holiday = SlaHoliday.first
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      put "/sla/holidays/#{sla_holiday.id}.xml",
        :params => {:sla_holiday => {name: 'API Test'}},
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end
 
  test "PUT /sla/holidays/:id.xml should unauthorized withtout credentials" do
    sla_holiday = SlaHoliday.first
    put "/sla/holidays/#{sla_holiday.id}.xml",
      :params => {:sla_holiday => {name: 'API Test'}}
    assert_response :unauthorized
  end  

  # SlaHoliday#destroy in XML

  test "DELETE /sla/holidays/:id.xml should success for admin" do
    sla_holiday = SlaHoliday.generate!
    sla_holiday_id = sla_holiday.id
    assert_difference('SlaHoliday.count',-1) do
      delete "/sla/holidays/#{sla_holiday_id}.xml",
        :headers => credentials('admin')
    end
    assert_response :no_content
    assert_equal '', @response.body
    assert_nil SlaHoliday.find_by(id: sla_holiday_id)
  end

  test "DELETE /sla/holidays/:id.xml should forbidden for other users" do
    sla_holiday = SlaHoliday.generate!
    sla_holiday_id = sla_holiday.id
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      delete "/sla/holidays/#{sla_holiday_id}.xml",
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end
 
  test "DELETE /sla/holidays/:id.json should unauthorized withtout credentials" do
    sla_holiday = SlaHoliday.generate!
    sla_holiday_id = sla_holiday.id
    delete "/sla/holidays/#{sla_holiday_id}.xml"
    assert_response :unauthorized
  end    

  private

  def assert_sla_holiday_show_xml(sla_holiday)
    assert_equal 'application/xml', @response.media_type
    assert_select 'sla_holiday>id', :integer => sla_holiday.id
    assert_select 'sla_holiday>name', :text => sla_holiday.name
    assert_select 'sla_holiday>date', :text => sla_holiday.date.strftime("%Y-%m-%d")
  end

  def assert_sla_holidays_index_xml(sla_holiday,sla_holiday_count)
    assert_equal 'application/xml', @response.media_type
    assert_select 'sla_holidays' do
      assert_select '[total_count=?]', sla_holiday_count
    end    
    assert_select 'sla_holidays>sla_holiday:first-child' do
      assert_select '>id', :integer => sla_holiday.id
      assert_select '>name', :text => sla_holiday.name
      assert_select '>date', :text => sla_holiday.date.strftime("%Y-%m-%d")
    end
  end

  def assert_sla_holiday_show_json(sla_holiday)
    assert_equal 'application/json', @response.media_type
    json = ActiveSupport::JSON.decode(response.body)
    assert_kind_of Hash, json
    assert_kind_of Hash, json['sla_holiday']
    assert_equal sla_holiday.id, json['sla_holiday']['id']
    assert_equal sla_holiday.name, json['sla_holiday']['name']
    assert_equal sla_holiday.date.strftime("%Y-%m-%d"), json['sla_holiday']['date']
  end

  def assert_sla_holidays_index_json(sla_holiday,sla_holiday_count)
    assert_equal 'application/json', @response.media_type
    json = ActiveSupport::JSON.decode(response.body)
    assert_kind_of Hash, json
    assert_kind_of Array, json['sla_holidays']
    assert_kind_of Hash, json['sla_holidays'].first
    assert json['sla_holidays'].first.has_key?('id')
    assert json['sla_holidays'].first.has_key?('name')
    assert json['sla_holidays'].first.has_key?('date')
    assert_equal(sla_holiday.id, json['sla_holidays'].first['id'])
    assert_equal(sla_holiday.name, json['sla_holidays'].first['name'])
    assert_equal(sla_holiday.date.strftime("%Y-%m-%d"), json['sla_holidays'].first['date'])
    assert_equal(sla_holiday_count, json['total_count'])
  end


end