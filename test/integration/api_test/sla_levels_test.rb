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

class Redmine::ApiTest::SlaLevelsTest < Redmine::ApiTest::Base
  include ActiveJob::TestHelper

  # SlaLevel#index in XML

  test "GET /sla/levels.xml should success for admin" do
    sla_level = SlaLevel.order(:id).first
    sla_level_count = SlaLevel.count
    ['admin'].each do |user|
      get "/sla/levels.xml?sort=id",
        :headers=>credentials(user)
      assert_response :success
      assert_sla_levels_index_xml(sla_level,sla_level_count)
    end
  end

  test "GET /sla/levels.xml should forbidden for other users" do
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      get "/sla/levels.xml",
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end

  test "GET /sla/levels.xml should unauthorized withtout credentials" do
      get "/sla/levels.xml"
      assert_response :unauthorized
  end    

  # SlaLevel#index in JSON

  test "GET /sla/levels.json should success for admin" do
    sla_level = SlaLevel.order(:id).first
    sla_level_count = SlaLevel.count
    ['admin'].each do |user|
      get "/sla/levels.json?sort=id",
        :headers => credentials(user)
      assert_response :success
      assert_sla_levels_index_json(sla_level,sla_level_count)
    end
  end

  test "GET /sla/levels.json should forbidden for other users" do
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      get "/sla/levels.json",
        :headers => credentials(user)
      assert_response :forbidden
    end
  end  

  test "GET /sla/levels.json should unauthorized withtout credentials" do
      get "/sla/levels.json"
      assert_response :unauthorized
  end   

  # SlaLevel#show in XML

  test "GET /sla/levels/:id.xml should success for admin" do
    sla_level = SlaLevel.order(:id).first
    ['admin','manager','developer','sysadmin'].each do |user|
      get "/sla/levels/#{sla_level.id}.xml",
        :headers=>credentials(user)
      assert_response :success
      assert_sla_level_show_xml(sla_level)
    end
  end

  test "GET /sla/levels/:id.xml should forbidden for other users" do
    sla_level = SlaLevel.order(:id).first
    ['reporter','other'].each do |user|
      get "/sla/levels/#{sla_level.id}.xml",
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end

  test "GET /sla/levels/:id.xml should unauthorized withtout credentials" do
    sla_level = SlaLevel.first
    get "/sla/levels/#{sla_level.id}.xml"
    assert_response :unauthorized
  end   

  # SlaLevel#show in JSON

  test "GET /sla/levels/:id.json should success for admin" do
    sla_level = SlaLevel.first
    ['admin'].each do |user|
      get "/sla/levels/#{sla_level.id}.json",
        :headers => credentials(user)
      assert_response :success
      assert_sla_level_show_json(sla_level)
    end
  end

  test "GET /sla/levels/:id.json should success for users with view_sla permission" do
    sla_level = SlaLevel.first
    ['manager','developer','sysadmin'].each do |user|
      get "/sla/levels/#{sla_level.id}.json",
        :headers=>credentials(user)
      assert_response :success
      assert_sla_level_show_json(sla_level)
    end
  end

  test "GET /sla/levels/:id.json should forbidden for ohter users" do
    sla_level = SlaLevel.first
    ['reporter','other'].each do |user|
      get "/sla/levels/#{sla_level.id}.json",
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end 
 
  test "GET /sla/levels/:id.json should forbidden withtout credentials" do
    sla_level = SlaLevel.first
    get "/sla/levels/#{sla_level.id}.json"
    assert_response :unauthorized
  end  

  # SlaLevel#create in XML

  test "POST /sla/levels.xml with blank parameters should unprocessable_entity for admin" do
    assert_no_difference('SlaLevel.count') do
      post "/sla/levels.xml",
        :params => {:sla_level => {sla_id: Sla.generate!.id, sla_calendar_id: SlaCalendar.generate!.id}},
        :headers => credentials('admin')
    end
    assert_response :unprocessable_entity
    assert_equal 'application/xml', @response.media_type
    assert_select 'errors error', :text => "Name cannot be blank"    
    assert_no_difference('SlaLevel.count') do
      post "/sla/levels.xml",
        :params => {:sla_level => { name: 'API Test', sla_calendar_id: SlaCalendar.generate!.id }},
        :headers => credentials('admin')
    end
    assert_response :unprocessable_entity
    assert_equal 'application/xml', @response.media_type
    assert_select 'errors error', :text => "Service Level Agreement cannot be blank"    
    assert_no_difference('SlaLevel.count') do
      post "/sla/levels.xml",
        :params => {:sla_level => { name: 'API Test', sla_id: Sla.generate!.id}},
        :headers => credentials('admin')
    end
    assert_response :unprocessable_entity
    assert_equal 'application/xml', @response.media_type
    assert_select 'errors error', :text => "SLA Calendar cannot be blank"    
  end

  test "POST /sla/levels.xml with invalid parameters should unprocessable_entity for admin" do
    sla_level = SlaLevel.first
    assert_no_difference('SlaLevel.count') do
      post "/sla/levels.xml",
        :params => {:sla_level => {name: sla_level.name, sla_id: sla_level.sla_id, sla_calendar_id: sla_level.sla_calendar_id, }},
        :headers => credentials('admin')
    end
    assert_response :unprocessable_entity
    assert_equal 'application/xml', @response.media_type
    assert_select 'errors error', :text => "Name has already been taken"
  end

  test "POST /sla/levels.xml with valid parameters should success for admin" do
    assert_difference('SlaLevel.count',1) do
      post "/sla/levels.xml",
      :params => {:sla_level => { name: 'API Test', sla_id: Sla.generate!.id, sla_calendar_id: SlaCalendar.generate!.id, custom_field_id: nil }},
        :headers => credentials('admin')
    end
    assert_response :success
    assert_equal 'application/xml', @response.media_type
  end

  test "POST /sla/levels.xml should forbidden for other users" do
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      post "/sla/levels.xml",
        :params => {:sla_level => { name: 'API Test', sla_id: Sla.generate!.id, sla_calendar_id: SlaCalendar.generate!.id, custom_field_id: nil }},
        :headers => credentials(user)
      assert_response :forbidden
    end
  end
 
  test "POST /sla/levels.xml should unauthorized withtout credentials" do
    post "/sla/levels.xml",
      :params => {:sla_level => { name: 'API Test', sla_id: Sla.generate!.id, sla_calendar_id: SlaCalendar.generate!.id, custom_field_id: nil }}
    assert_response :unauthorized
  end      

  # SlaLevel#update in XML

  test "PUT /sla/levels/:id.xml with blank parameters should unprocessable_entity for admin" do
    sla_level = SlaLevel.first
    assert_no_difference('SlaLevel.count') do
      put "/sla/levels/#{sla_level.id}.xml",
        :params => {:sla_level => {name: ''}},
        :headers => credentials('admin')
    end
    assert_response :unprocessable_entity
    assert_equal 'application/xml', @response.media_type
    assert_select 'errors', :text => "Name cannot be blank"
  end

  test "PUT /sla/levels/:id.xml with invalid parameters should unprocessable_entity for admin" do
    sla_level = SlaLevel.first
    sla_level_last = SlaLevel.last
    assert_no_difference('SlaLevel.count') do
      put "/sla/levels/#{sla_level.id}.xml",
        :params => {:sla_level => {name: sla_level_last.name, sla_id: Sla.generate!.id, sla_calendar_id: SlaCalendar.generate!.id}},
        :headers => credentials('admin')
    end
    assert_response :unprocessable_entity
    assert_equal 'application/xml', @response.media_type
    assert_select 'errors', :text => "Name has already been taken"
    sla_level = SlaLevel.first
    sla_level_last = SlaLevel.last
    assert_no_difference('SlaLevel.count') do
      put "/sla/levels/#{sla_level.id}.xml",
        :params => {:sla_level => {name: 'API update', sla_id: sla_level_last.sla_id, sla_calendar_id: sla_level_last.sla_calendar_id}},
        :headers => credentials('admin')
    end
    assert_response :unprocessable_entity
    assert_equal 'application/xml', @response.media_type
    assert_select 'errors', :text => "Service Level Agreement has already been taken"    
  end

  test "PUT /sla/levels/:id.xml with valid parameters should update the sla_level" do
    sla_level = SlaLevel.first
    assert_no_difference 'SlaLevel.count' do
      put "/sla/levels/#{sla_level.id}.xml",
        :params => {:sla_level => {name: 'API update'}},
        :headers => credentials('admin')
    end
    assert_response :no_content
    assert_equal '', @response.body
    assert_nil @response.media_type
    sla_level = SlaLevel.find(sla_level.id)
    assert_equal 'API update', sla_level.name
  end

  test "PUT /sla/levels/:id.xml should forbidden for other users" do
    sla_level = SlaLevel.first
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      put "/sla/levels/#{sla_level.id}.xml",
        :params => {:sla_level => {name: 'API Test'}},
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end
 
  test "PUT /sla/levels/:id.xml should unauthorized withtout credentials" do
    sla_level = SlaLevel.first
    put "/sla/levels/#{sla_level.id}.xml",
      :params => {:sla_level => {name: 'API Test'}}
    assert_response :unauthorized
  end  

  # SlaLevel#destroy in XML

  test "DELETE /sla/levels/:id.xml should success for admin" do
    sla_level = SlaLevel.generate!
    sla_level_id = sla_level.id
    assert_difference('SlaLevel.count',-1) do
      delete "/sla/levels/#{sla_level_id}.xml",
        :headers => credentials('admin')
    end
    assert_response :no_content
    assert_equal '', @response.body
    assert_nil SlaLevel.find_by(id: sla_level_id)
  end

  test "DELETE /sla/levels/:id.xml should forbidden for other users" do
    sla_level = SlaLevel.generate!
    sla_level_id = sla_level.id
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      delete "/sla/levels/#{sla_level_id}.xml",
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end
 
  test "DELETE /sla/levels/:id.json should unauthorized withtout credentials" do
    sla_level = SlaLevel.generate!
    sla_level_id = sla_level.id
    delete "/sla/levels/#{sla_level_id}.xml"
    assert_response :unauthorized
  end    

  private

  def assert_sla_level_show_xml(sla_level)
    assert_equal 'application/xml', @response.media_type
    assert_select 'sla_level>id', :integer => sla_level.id
    assert_select 'sla_level>name', :text => sla_level.name
    assert_select 'sla_level>sla', :integer => sla_level.sla_id
    assert_select 'sla_level>sla_calendar', :integer => sla_level.sla_calendar_id
    assert_select 'sla_level>custom_field', :integer => sla_level.custom_field_id
  end

  def assert_sla_levels_index_xml(sla_level,sla_level_count)
    assert_equal 'application/xml', @response.media_type
    assert_select 'sla_levels' do
      assert_select '[total_count=?]', sla_level_count
    end    
    assert_select 'sla_levels>sla_level:first-child' do
      assert_select '>id', :integer => sla_level.id
      assert_select '>name', :text => sla_level.name
      assert_select '>sla_id', :integer => sla_level.sla_id
      assert_select '>sla_calendar_id', :integer => sla_level.sla_calendar_id
      assert_select '>custom_field_id', :integer => sla_level.custom_field_id
    end
  end

  def assert_sla_level_show_json(sla_level)
    assert_equal 'application/json', @response.media_type
    json = ActiveSupport::JSON.decode(response.body)
    assert_kind_of Hash, json
    assert_kind_of Hash, json['sla_level']
    assert_equal(sla_level.id, json['sla_level']['id'])
    assert_equal(sla_level.name, json['sla_level']['name'])
    assert_equal(sla_level.sla_id, json['sla_level']['sla']['id'])
    assert_equal(sla_level.sla_calendar_id, json['sla_level']['sla_calendar']['id'])
    assert_equal(sla_level.custom_field_id, json['sla_level']['custom_field']['id']) unless sla_level.custom_field_id.nil?
  end

  def assert_sla_levels_index_json(sla_level,sla_level_count)
    assert_equal 'application/json', @response.media_type
    json = ActiveSupport::JSON.decode(response.body)
    assert_kind_of Hash, json
    assert_kind_of Array, json['sla_levels']
    assert_kind_of Hash, json['sla_levels'].first
    assert json['sla_levels'].first.has_key?('id')
    assert json['sla_levels'].first.has_key?('name')
    assert json['sla_levels'].first.has_key?('sla_id')
    assert json['sla_levels'].first.has_key?('sla_calendar_id')
    assert json['sla_levels'].first.has_key?('custom_field_id')
    assert_equal(sla_level.id, json['sla_levels'].first['id'])
    assert_equal(sla_level.name, json['sla_levels'].first['name'])
    assert_equal(sla_level.sla_id, json['sla_levels'].first['sla_id'])
    assert_equal(sla_level.sla_calendar_id, json['sla_levels'].first['sla_calendar_id'])
    assert_equal(sla_level.custom_field_id, json['sla_levels'].first['custom_field_id']) unless sla_level.custom_field_id.nil?
    assert_equal(sla_level_count, json['total_count'])
  end


end