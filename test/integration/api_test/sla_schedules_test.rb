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

class Redmine::ApiTest::SlaSchedulesTest < Redmine::ApiTest::Base
  include ActiveJob::TestHelper

  # SlaSchedule#index in XML

  test "GET /sla/schedules.xml should success for admin" do
    sla_schedule = SlaSchedule.order(:id).first
    sla_schedule_count = SlaSchedule.count.to_s
    ['admin'].each do |user|
      get "/sla/schedules.xml?sort=id",
        :headers=>credentials(user)
      assert_response :success
      assert_sla_schedules_index_xml(sla_schedule,sla_schedule_count)
    end
  end

  test "GET /sla/schedules.xml should forbidden for other users" do
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      get "/sla/schedules.xml",
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end

  test "GET /sla/schedules.xml should unauthorized withtout credentials" do
      get "/sla/schedules.xml"
      assert_response :unauthorized
  end    

  # SlaSchedule#index in JSON

  test "GET /sla/schedules.json should success for admin" do
    sla_schedule = SlaSchedule.order(:id).first
    sla_schedule_count = SlaSchedule.count
    ['admin'].each do |user|
      get "/sla/schedules.json?sort=id",
        :headers => credentials(user)
      assert_response :success
      assert_sla_schedules_index_json(sla_schedule,sla_schedule_count)
    end
  end

  test "GET /sla/schedules.json should forbidden for other users" do
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      get "/sla/schedules.json",
        :headers => credentials(user)
      assert_response :forbidden
    end
  end  

  test "GET /sla/schedules.json should unauthorized withtout credentials" do
      get "/sla/schedules.json"
      assert_response :unauthorized
  end   

  # SlaSchedule#show in XML

  test "GET /sla/schedules/:id.xml should success for admin" do
    sla_schedule = SlaSchedule.first
    ['admin'].each do |user|
      get "/sla/schedules/#{sla_schedule.id}.xml",
        :headers=>credentials(user)
      assert_response :success
      assert_sla_schedule_show_xml(sla_schedule)
    end
  end

  test "GET /sla/schedules/:id.xml should success for project's members" do
    sla_schedule = SlaSchedule.first
    ['manager','developer'].each do |user|
      get "/sla/schedules/#{sla_schedule.id}.xml",
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end  

  test "GET /sla/schedules/:id.xml should forbidden for other users" do
    sla_schedule = SlaSchedule.first
    ['sysadmin','reporter','other'].each do |user|
      get "/sla/schedules/#{sla_schedule.id}.xml",
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end

  test "GET /sla/schedules/:id.xml should unauthorized withtout credentials" do
    sla_schedule = SlaSchedule.first
    get "/sla/schedules/#{sla_schedule.id}.xml"
    assert_response :unauthorized
  end   

  # SlaSchedule#show in JSON

  test "GET /sla/schedules/:id.json should success for admin" do
    sla_schedule = SlaSchedule.first
    ['admin'].each do |user|
      get "/sla/schedules/#{sla_schedule.id}.json",
        :headers => credentials(user)
      assert_response :success
      assert_sla_schedule_show_json(sla_schedule)
    end
  end

  test "GET /sla/schedules/:id.json should forbidden for project's members" do
    sla_schedule = SlaSchedule.first
    ['manager','developer'].each do |user|
      get "/sla/schedules/#{sla_schedule.id}.json",
        :headers => credentials(user)
      assert_response :forbidden
    end
  end  

  test "GET /sla/schedules/:id.json should forbidden for ohter users" do
    sla_schedule = SlaSchedule.first
    ['sysadmin','reporter','other'].each do |user|
      get "/sla/schedules/#{sla_schedule.id}.json",
        :headers => credentials(user)
      assert_response :forbidden
    end
  end
 
  test "GET /sla/schedules/:id.json should forbidden withtout credentials" do
    sla_schedule = SlaSchedule.first
    get "/sla/schedules/#{sla_schedule.id}.json"
    assert_response :unauthorized
  end  

  # SlaSchedule#create in XML

  test "POST /sla/schedules.xml with blank parameters should unprocessable_entity for admin" do
    assert_no_difference('SlaSchedule.count') do
      post "/sla/schedules.xml",
        :params => {:sla_schedule => {
          dow: '',
          sla_calendar_id: 1,
          #start_time: '09:00',
          #end_time: '17:00',
        }},
        :headers => credentials('admin')
    end
    assert_response :unprocessable_entity
    assert_equal 'application/xml', @response.media_type
    assert_select 'errors error', :text => "Dow cannot be blank"
  end

  test "POST /sla/schedules.xml with invalid parameters should unprocessable_entity for admin" do
    sla_schedule = SlaSchedule.first
    assert_no_difference('SlaSchedule.count') do
      post "/sla/schedules.xml",
        :params => {:sla_schedule => {
          dow: sla_schedule.dow,
          sla_calendar_id: 1,
          #start_time: '09:00',
          #end_time: '17:00',
        }},
        :headers => credentials('admin')
    end
    assert_response :unprocessable_entity
    assert_equal 'application/xml', @response.media_type
    assert_select 'errors error', :text => "Start time cannot be blank"
  end

test "POST /sla/schedules.xml with valid parameters should success for admin" do
    assert_difference('SlaSchedule.count',1) do
      post "/sla/schedules.xml",
        :params => {:sla_schedule => {
          dow: 6,
          sla_calendar_id: 1,
          start_time: '09:00',
          end_time: '17:00',
          match: true,
        }},
        :headers => credentials('admin')
    end
    assert_response :success
    assert_equal 'application/xml', @response.media_type
  end  

  test "POST /sla/schedules.xml should forbidden for other users" do
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      post "/sla/schedules.xml",
        :params => {:sla_schedule => { :dow => '1' } },
        :headers => credentials(user)
      assert_response :forbidden
    end
  end
 
  test "POST /sla/schedules.xml should unauthorized withtout credentials" do
    post "/sla/schedules.xml",
      :params => {:sla_schedule => { dow: '1'} }
    assert_response :unauthorized
  end      

  # SlaSchedule#update in XML

  test "PUT /sla/schedules/:id.xml with blank parameters should unprocessable_entity for admin" do
    sla_schedule = SlaSchedule.first
    assert_no_difference('SlaSchedule.count') do
      put "/sla/schedules/#{sla_schedule.id}.xml",
        :params => {:sla_schedule => {dow: ''}},
        :headers => credentials('admin')
    end
    assert_response :unprocessable_entity
    assert_equal 'application/xml', @response.media_type
    assert_select 'errors', :text => "Dow cannot be blank"
  end

  # TODO: test "PUT /sla/schedules/:id.xml with invalid parameters should unprocessable_entity for admin" do

  test "PUT /sla/schedules/:id.xml with valid parameters should update the sla_schedule" do
    sla_schedule = SlaSchedule.first
    assert_no_difference 'SlaSchedule.count' do
      put "/sla/schedules/#{sla_schedule.id}.xml",
        :params => {:sla_schedule => {dow: '1'}},
        :headers => credentials('admin')
    end
    assert_response :no_content
    assert_equal '', @response.body
    assert_nil @response.media_type
    sla_schedule = SlaSchedule.find(sla_schedule.id)
    assert_equal '1', sla_schedule.dow.to_s
  end

  test "PUT /sla/schedules/:id.xml should forbidden for other users" do
    sla_schedule = SlaSchedule.first
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      put "/sla/schedules/#{sla_schedule.id}.xml",
        :params => {:sla_schedule => {dow: '1'}},
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end
 
  test "PUT /sla/schedules/:id.xml should unauthorized withtout credentials" do
    sla_schedule = SlaSchedule.first
    put "/sla/schedules/#{sla_schedule.id}.xml",
      :params => {:sla_schedule => {dow: '1'}}
    assert_response :unauthorized
  end  

  # SlaSchedule#destroy in XML

  test "DELETE /sla/schedules/:id.xml should success for admin" do
    sla_schedule = SlaSchedule.generate!
    sla_schedule_id = sla_schedule.id
    assert_difference('SlaSchedule.count',-1) do
      delete "/sla/schedules/#{sla_schedule_id}.xml",
        :headers => credentials('admin')
    end
    assert_response :no_content
    assert_equal '', @response.body
    assert_nil SlaSchedule.find_by(id: sla_schedule_id)
  end

  test "DELETE /sla/schedules/:id.xml should forbidden for other users" do
    sla_schedule = SlaSchedule.generate!
    sla_schedule_id = sla_schedule.id
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      delete "/sla/schedules/#{sla_schedule_id}.xml",
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end
 
  test "DELETE /sla/schedules/:id.json should unauthorized withtout credentials" do
    sla_schedule = SlaSchedule.generate!
    sla_schedule_id = sla_schedule.id
    delete "/sla/schedules/#{sla_schedule_id}.xml"
    assert_response :unauthorized
  end    

  private

  def assert_sla_schedule_show_xml(sla_schedule)
    assert_equal 'application/xml', @response.media_type
    assert_select 'sla_schedule>id', :integer => sla_schedule.id
    assert_select 'sla_schedule>dow', :integer => sla_schedule.dow
  end

  def assert_sla_schedules_index_xml(sla_schedule,sla_schedule_count)
    assert_equal 'application/xml', @response.media_type
    assert_select 'sla_schedules' do
      assert_select '[total_count=?]', sla_schedule_count
    end    
    assert_select 'sla_schedules>sla_schedule:first-child' do
      assert_select '>id', :integer => sla_schedule.id
      assert_select '>dow', :integer => sla_schedule.dow
    end
  end

  def assert_sla_schedule_show_json(sla_schedule)
    assert_equal 'application/json', @response.media_type
    json = ActiveSupport::JSON.decode(response.body)
    assert_kind_of Hash, json
    assert_kind_of Hash, json['sla_schedule']
    assert_equal sla_schedule.id, json['sla_schedule']['id']
    assert_equal sla_schedule.dow, json['sla_schedule']['dow']
  end

  def assert_sla_schedules_index_json(sla_schedule,sla_schedule_count)
    assert_equal 'application/json', @response.media_type
    json = ActiveSupport::JSON.decode(response.body)
    assert_kind_of Hash, json
    assert_kind_of Array, json['sla_schedules']
    assert_kind_of Hash, json['sla_schedules'].first
    assert json['sla_schedules'].first.has_key?('id')
    assert json['sla_schedules'].first.has_key?('dow')
    assert_equal(sla_schedule.id, json['sla_schedules'].first['id'])
    assert_equal(sla_schedule.dow, json['sla_schedules'].first['dow'])
    assert_equal(sla_schedule_count, json['total_count'])
  end


end