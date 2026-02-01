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

class Redmine::ApiTest::SlaStatusesTest < ApplicationSlaApiTestCase
  include ActiveJob::TestHelper

  # SlaStatus#index in XML

  test "GET /sla/statuses.xml should success for admin" do
    sla_status = SlaStatus.first
    count = SlaStatus.count
    ['admin'].each do |user|
      get "/sla/statuses.xml",
        :headers=>credentials(user)
      assert_response :success
      assert_sla_statuses_index_xml(sla_status,count)
    end
  end

  test "GET /sla/statuses.xml should forbidden for other users" do
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      get "/sla/statuses.xml",
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end

  test "GET /sla/statuses.xml should unauthorized withtout credentials" do
      get "/sla/statuses.xml"
      assert_response :unauthorized
  end    

  # SlaStatus#index in JSON

  test "GET /sla/statuses.json should success for admin" do
    sla_status = SlaStatus.first
    count = SlaStatus.count
    ['admin'].each do |user|
      get "/sla/statuses.json",
        :headers => credentials(user)
      assert_response :success
      assert_sla_statuses_index_json(sla_status,count)
    end
  end

  test "GET /sla/statuses.json should forbidden for other users" do
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      get "/sla/statuses.json",
        :headers => credentials(user)
      assert_response :forbidden
    end
  end  

  test "GET /sla/statuses.json should unauthorized withtout credentials" do
      get "/sla/statuses.json"
      assert_response :unauthorized
  end   

  # SlaStatus#show in XML

  test "GET /sla/statuses/:id.xml should success for admin" do
    sla_status = SlaStatus.first
    ['admin'].each do |user|
      get "/sla/statuses/#{sla_status.id}.xml",
        :headers=>credentials(user)
      assert_response :success
      assert_sla_status_show_xml(sla_status)
    end
  end

  test "GET /sla/statuses/:id.xml should forbidden for other users" do
    sla_status = SlaStatus.first
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      get "/sla/statuses/#{sla_status.id}.xml",
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end

  test "GET /sla/statuses/:id.xml should unauthorized withtout credentials" do
    sla_status = SlaStatus.first
    get "/sla/statuses/#{sla_status.id}.xml"
    assert_response :unauthorized
  end   

  # SlaStatus#show in JSON

  test "GET /sla/statuses/:id.json should success for admin" do
    sla_status = SlaStatus.first
    ['admin'].each do |user|
      get "/sla/statuses/#{sla_status.id}.json",
        :headers => credentials(user)
      assert_response :success
      assert_sla_status_show_json(sla_status)
    end
  end

  test "GET /sla/statuses/:id.json should forbidden for ohter users" do
    sla_status = SlaStatus.first
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      get "/sla/statuses/#{sla_status.id}.json",
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end
 
  test "GET /sla/statuses/:id.json should forbidden withtout credentials" do
    sla_status = SlaStatus.first
    get "/sla/statuses/#{sla_status.id}.json"
    assert_response :unauthorized
  end  

  # SlaStatus#create in XML

  test "POST /sla/statuses.xml with blank parameters should unprocessable_entity for admin" do
    assert_no_difference('SlaStatus.count') do
      post "/sla/statuses.xml",
        :params => {:sla_status => {
          :sla_type_id => nil,
          :status_id => nil,
        }},
        :headers => credentials('admin')
    end
    assert_response :unprocessable_entity
    assert_equal 'application/xml', @response.media_type
    assert_select 'errors error', :text => "SLA Type cannot be blank"
  end

  test "POST /sla/statuses.xml with invalid parameters should unprocessable_entity for admin" do
    sla_status = SlaStatus.first
    assert_no_difference('SlaStatus.count') do
      post "/sla/statuses.xml",
        :params => {:sla_status => {
          :sla_type_id => sla_status.sla_type_id,
          :status_id => sla_status.status_id,
        }},
        :headers => credentials('admin')
    end
    assert_response :unprocessable_entity
    assert_equal 'application/xml', @response.media_type
    assert_select 'errors error', :text => "SLA Type has already been taken"
  end

  test "POST /sla/statuses.xml with valid parameters should success for admin" do
    assert_difference('SlaStatus.count',1) do
      post "/sla/statuses.xml",
      :params => {:sla_status => {
        :sla_type_id => 1,
        :status_id => 3,
      }},
      :headers => credentials('admin')
    end
    assert_response :success
    assert_equal 'application/xml', @response.media_type
  end

  test "POST /sla/statuses.xml should forbidden for other users" do
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      post "/sla/statuses.xml",
        :params => {:sla_status => {
          :sla_type_id => 1,
          :status_id => 3,
        }},
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end
 
  test "POST /sla/statuses.xml should unauthorized withtout credentials" do
    post "/sla/statuses.xml",
    :params => {:sla_status => {
      :sla_type_id => 1,
      :status_id => 3,
    }}
    assert_response :unauthorized
  end      

  # SlaStatus#update in XML

  test "PUT /sla/statuses/:id.xml with blank parameters should unprocessable_entity for admin" do
    sla_status = SlaStatus.first
    assert_no_difference('SlaStatus.count') do
      put "/sla/statuses/#{sla_status.id}.xml",
        :params => {:sla_status => {
          :sla_type_id => nil,
          :status_id => nil,
        }},
        :headers => credentials('admin')
    end
    assert_response :unprocessable_entity
    assert_equal 'application/xml', @response.media_type
    assert_select 'errors', :text => "SLA Type cannot be blankStatus cannot be blank"
  end

  test "PUT /sla/statuses/:id.xml with invalid parameters should unprocessable_entity for admin" do
    sla_status = SlaStatus.first
    sla_status_last = SlaStatus.last
    assert_no_difference('SlaStatus.count') do
      put "/sla/statuses/#{sla_status.id}.xml",
        :params => {:sla_status => {
          :sla_type_id => sla_status_last.sla_type_id,
          :status_id => sla_status_last.status_id,
        }},
        :headers => credentials('admin')
    end
    assert_response :unprocessable_entity
    assert_equal 'application/xml', @response.media_type
    assert_select 'errors', :text => "SLA Type has already been taken"
  end

  test "PUT /sla/statuses/:id.xml with valid parameters should update the sla_status" do
    sla_status = SlaStatus.first
    assert_no_difference 'SlaStatus.count' do
      put "/sla/statuses/#{sla_status.id}.xml",
        :params => {:sla_status => {
          :sla_type_id => 1,
          :status_id => 3,
        }},
        :headers => credentials('admin')
    end
    assert_response :no_content
    assert_equal '', @response.body
    assert_nil @response.media_type
    sla_status = SlaStatus.find(sla_status.id)
    assert_equal 1, sla_status.sla_type_id
    assert_equal 3, sla_status.status_id
  end

  test "PUT /sla/statuses/:id.xml should forbidden for other users" do
    sla_status = SlaStatus.first
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      put "/sla/statuses/#{sla_status.id}.xml",
        :params => {:sla_status => {
          :sla_type_id => 1,
          :status_id => 3,
        }},
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end
 
  test "PUT /sla/statuses/:id.xml should unauthorized withtout credentials" do
    sla_status = SlaStatus.first
    put "/sla/statuses/#{sla_status.id}.xml",
      :params => {:sla_status => {
        :sla_type_id => 1,
        :status_id => 3,
      }}
    assert_response :unauthorized
  end  

  # SlaStatus#destroy in XML

  test "DELETE /sla/statuses/:id.xml should success for admin" do
    sla_status = SlaStatus.generate!
    sla_status_id = sla_status.id
    assert_difference('SlaStatus.count',-1) do
      delete "/sla/statuses/#{sla_status_id}.xml",
        :headers => credentials('admin')
    end
    assert_response :no_content
    assert_equal '', @response.body
    assert_nil SlaStatus.find_by(id: sla_status_id)
  end

  test "DELETE /sla/statuses/:id.xml should forbidden for other users" do
    sla_status = SlaStatus.generate!
    sla_status_id = sla_status.id
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      delete "/sla/statuses/#{sla_status_id}.xml",
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end
 
  test "DELETE /sla/statuses/:id.json should unauthorized withtout credentials" do
    sla_status = SlaStatus.generate!
    sla_status_id = sla_status.id
    delete "/sla/statuses/#{sla_status_id}.xml"
    assert_response :unauthorized
  end    

  private

  def assert_sla_status_show_xml(sla_status)
    assert_equal 'application/xml', @response.media_type
    assert_select 'sla_status>id', :integer => sla_status.id
    assert_select 'sla_status>status', :integer => sla_status.status
    assert_select 'sla_status>sla_type', :integer => sla_status.sla_type
  end

  def assert_sla_statuses_index_xml(sla_status,count)
    assert_equal 'application/xml', @response.media_type
    assert_select 'sla_statuses' do
      assert_select '[total_count=?]', count
    end    
    assert_select 'sla_statuses>sla_status:first-child' do
      assert_select '>id', :integer => sla_status.id
      assert_select '>status_id', :integer => sla_status.status_id
      assert_select '>sla_type_id', :integer => sla_status.sla_type_id
    end
  end

  def assert_sla_status_show_json(sla_status)
    assert_equal 'application/json', @response.media_type
    json = ActiveSupport::JSON.decode(response.body)
    assert_kind_of Hash, json
    assert_kind_of Hash, json['sla_status']
    assert_equal sla_status.id, json['sla_status']['id']
    assert_equal sla_status.status.id, json['sla_status']['status']['id']
    assert_equal sla_status.sla_type.id, json['sla_status']['sla_type']['id']
  end

  def assert_sla_statuses_index_json(sla_status,count)
    assert_equal 'application/json', @response.media_type
    json = ActiveSupport::JSON.decode(response.body)
    assert_kind_of Hash, json
    assert_kind_of Array, json['sla_statuses']
    assert_kind_of Hash, json['sla_statuses'].first
    assert json['sla_statuses'].first.has_key?('id')
    assert json['sla_statuses'].first.has_key?('status_id')
    assert json['sla_statuses'].first.has_key?('sla_type_id')
    assert_equal(sla_status.id, json['sla_statuses'].first['id'])
    assert_equal(sla_status.status_id, json['sla_statuses'].first['status_id'])
    assert_equal(sla_status.sla_type_id, json['sla_statuses'].first['sla_type_id'])
    assert_equal(count, json['total_count'])
  end


end