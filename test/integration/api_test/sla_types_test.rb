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

class Redmine::ApiTest::SlaTypesTest < Redmine::ApiTest::Base
  include ActiveJob::TestHelper

  # SlaType#index in XML

  test "GET /sla/types.xml should success for admin" do
    sla_type = SlaType.first
    count = SlaType.count
    ['admin'].each do |user|
      get "/sla/types.xml",
        :headers=>credentials(user)
      assert_response :success
      assert_sla_types_index_xml(sla_type,count)
    end
  end

  test "GET /sla/types.xml should forbidden for other users" do
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      get "/sla/types.xml",
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end

  test "GET /sla/types.xml should unauthorized withtout credentials" do
      get "/sla/types.xml"
      assert_response :unauthorized
  end    

  # SlaType#index in JSON

  test "GET /sla/types.json should success for admin" do
    sla_type = SlaType.first
    sla_type_count = SlaType.count
    ['admin'].each do |user|
      get "/sla/types.json",
        :headers => credentials(user)
      assert_response :success
      assert_sla_types_index_json(sla_type,sla_type_count)
    end
  end

  test "GET /sla/types.json should forbidden for other users" do
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      get "/sla/types.json",
        :headers => credentials(user)
      assert_response :forbidden
    end
  end  

  test "GET /sla/types.json should unauthorized withtout credentials" do
      get "/sla/types.json"
      assert_response :unauthorized
  end   

  # SlaType#show in XML

  test "GET /sla/types/:id.xml should success for admin" do
    sla_type = SlaType.first
    ['admin'].each do |user|
      get "/sla/types/#{sla_type.id}.xml",
        :headers=>credentials(user)
      assert_response :success
      assert_sla_type_show_xml(sla_type)
    end
  end

  test "GET /sla/types/:id.xml should forbidden for other users" do
    sla_type = SlaType.first
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      get "/sla/types/#{sla_type.id}.xml",
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end

  test "GET /sla/types/:id.xml should unauthorized withtout credentials" do
    sla_type = SlaType.first
    get "/sla/types/#{sla_type.id}.xml"
    assert_response :unauthorized
  end   

  # SlaType#show in JSON

  test "GET /sla/types/:id.json should success for admin" do
    sla_type = SlaType.first
    ['admin'].each do |user|
      get "/sla/types/#{sla_type.id}.json",
        :headers => credentials(user)
      assert_response :success
      assert_sla_type_show_json(sla_type)
    end
  end

  test "GET /sla/types/:id.json should forbidden for ohter users" do
    sla_type = SlaType.first
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      get "/sla/types/#{sla_type.id}.json",
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end
 
  test "GET /sla/types/:id.json should forbidden withtout credentials" do
    sla_type = SlaType.first
    get "/sla/types/#{sla_type.id}.json"
    assert_response :unauthorized
  end  

  # SlaType#create in XML

  test "POST /sla/types.xml with blank parameters should unprocessable_entity for admin" do
    assert_no_difference('SlaType.count') do
      post "/sla/types.xml",
        :params => {:sla_type => {name: '' }},
        :headers => credentials('admin')
    end
    assert_response :unprocessable_entity
    assert_equal 'application/xml', @response.media_type
    assert_select 'errors error', :text => "Name cannot be blank"    
  end

  test "POST /sla/types.xml with invalid parameters should unprocessable_entity for admin" do
    sla_type = SlaType.first
    assert_no_difference('SlaType.count') do
      post "/sla/types.xml",
        :params => {:sla_type => {name: sla_type.name}},
        :headers => credentials('admin')
    end
    assert_response :unprocessable_entity
    assert_equal 'application/xml', @response.media_type
    assert_select 'errors error', :text => "Name has already been taken"
  end

  test "POST /sla/types.xml with valid parameters should success for admin" do
    assert_difference('SlaType.count',1) do
      post "/sla/types.xml",
        :params => {:sla_type => {name: 'API Test'}},
        :headers => credentials('admin')
    end
    assert_response :success
    assert_equal 'application/xml', @response.media_type
  end

  test "POST /sla/types.xml should forbidden for other users" do
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      post "/sla/types.xml",
        :params => {:sla_type => {name: 'API Test'}},
        :headers => credentials(user)
      assert_response :forbidden
    end
  end
 
  test "POST /sla/types.xml should unauthorized withtout credentials" do
    post "/sla/types.xml",
      :params => {:sla_type => {name: 'API Test'}}
    assert_response :unauthorized
  end      

  # SlaType#update in XML

  test "PUT /sla/types/:id.xml with blank parameters should unprocessable_entity for admin" do
    sla_type = SlaType.first
    assert_no_difference('SlaType.count') do
      put "/sla/types/#{sla_type.id}.xml",
        :params => {:sla_type => {name: ''}},
        :headers => credentials('admin')
    end
    assert_response :unprocessable_entity
    assert_equal 'application/xml', @response.media_type
    assert_select 'errors', :text => "Name cannot be blank"
  end

  test "PUT /sla/types/:id.xml with invalid parameters should unprocessable_entity for admin" do
    sla_type = SlaType.first
    sla_type_last = SlaType.last
    assert_no_difference('SlaType.count') do
      put "/sla/types/#{sla_type.id}.xml",
        :params => {:sla_type => {name: sla_type_last.name}},
        :headers => credentials('admin')
    end
    assert_response :unprocessable_entity
    assert_equal 'application/xml', @response.media_type
    assert_select 'errors', :text => "Name has already been taken"
  end

  test "PUT /sla/types/:id.xml with valid parameters should update the sla_type" do
    sla_type = SlaType.first
    assert_no_difference 'SlaType.count' do
      put "/sla/types/#{sla_type.id}.xml",
        :params => {:sla_type => {name: 'API update'}},
        :headers => credentials('admin')
    end
    assert_response :no_content
    assert_equal '', @response.body
    assert_nil @response.media_type
    sla_type = SlaType.find(sla_type.id)
    assert_equal 'API update', sla_type.name
  end

  test "PUT /sla/types/:id.xml should forbidden for other users" do
    sla_type = SlaType.first
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      put "/sla/types/#{sla_type.id}.xml",
        :params => {:sla_type => {name: 'API Test'}},
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end
 
  test "PUT /sla/types/:id.xml should unauthorized withtout credentials" do
    sla_type = SlaType.first
    put "/sla/types/#{sla_type.id}.xml",
      :params => {:sla_type => {name: 'API Test'}}
    assert_response :unauthorized
  end  

  # SlaType#destroy in XML

  test "DELETE /sla/types/:id.xml should success for admin" do
    sla_type = SlaType.generate!
    sla_type_id = sla_type.id
    assert_difference('SlaType.count',-1) do
      delete "/sla/types/#{sla_type_id}.xml",
        :headers => credentials('admin')
    end
    assert_response :no_content
    assert_equal '', @response.body
    assert_nil SlaType.find_by(id: sla_type_id)
  end

  test "DELETE /sla/types/:id.xml should forbidden for other users" do
    sla_type = SlaType.generate!
    sla_type_id = sla_type.id
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      delete "/sla/types/#{sla_type_id}.xml",
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end
 
  test "DELETE /sla/types/:id.json should unauthorized withtout credentials" do
    sla_type = SlaType.generate!
    sla_type_id = sla_type.id
    delete "/sla/types/#{sla_type_id}.xml"
    assert_response :unauthorized
  end    

  private

  def assert_sla_type_show_xml(sla_type)
    assert_equal 'application/xml', @response.media_type
    assert_select 'sla_type>id', :integer => sla_type.id
    assert_select 'sla_type>name', :text => sla_type.name
  end

  def assert_sla_types_index_xml(sla_type,count)
    assert_equal 'application/xml', @response.media_type
    assert_select 'sla_types' do
      assert_select '[total_count=?]', count
    end    
    assert_select 'sla_types>sla_type:first-child' do
      assert_select '>id', :integer => sla_type.id
      assert_select '>name', :text => sla_type.name
    end
  end

  def assert_sla_type_show_json(sla_type)
    assert_equal 'application/json', @response.media_type
    json = ActiveSupport::JSON.decode(response.body)
    assert_kind_of Hash, json
    assert_kind_of Hash, json['sla_type']
    assert_equal sla_type.id, json['sla_type']['id']
    assert_equal sla_type.name, json['sla_type']['name']
  end

  def assert_sla_types_index_json(sla_type,count)
    assert_equal 'application/json', @response.media_type
    json = ActiveSupport::JSON.decode(response.body)
    assert_kind_of Hash, json
    assert_kind_of Array, json['sla_types']
    assert_kind_of Hash, json['sla_types'].first
    assert json['sla_types'].first.has_key?('id')
    assert json['sla_types'].first.has_key?('name')
    assert_equal(sla_type.id, json['sla_types'].first['id'])
    assert_equal(sla_type.name, json['sla_types'].first['name'])
    assert_equal(count, json['total_count'])
  end


end