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

class Redmine::ApiTest::SlasTest < Redmine::ApiTest::Base
  include ActiveJob::TestHelper

  # Sla#index in XML

  test "GET /sla/slas.xml should success for admin" do
    sla = Sla.generate!
    count = Sla.count
    ['admin'].each do |user|
      get "/sla/slas.xml",
        :headers=>credentials(user)
      assert_response :success
      assert_sla_index_xml(sla,count)
    end
  end

  test "GET /sla/slas.xml should forbidden for other users" do
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      get "/sla/slas.xml",
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end

  test "GET /sla/slas.xml should forbidden withtout credentials" do
      get "/sla/slas.xml"
      assert_response :unauthorized
  end    

  # Sla#index in JSON

  test "GET /sla/slas.json should success for admin" do
    sla = Sla.generate!
    count = Sla.count
    ['admin'].each do |user|
      get "/sla/slas.json",
        :headers => credentials(user)
      assert_response :success
      assert_sla_index_json(sla,count)
    end
  end

  test "GET /sla/slas.json should forbidden for other users" do
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      get "/sla/slas.json",
        :headers => credentials(user)
      assert_response :forbidden
    end
  end  

  test "GET /sla/slas.json should forbidden withtout credentials" do
      get "/sla/slas.json"
      assert_response :unauthorized
  end   

  # Sla#show in XML

  test "GET /sla/slas/:id.xml should success for admin" do
    sla = Sla.first
    ['admin'].each do |user|
      get "/sla/slas/#{sla.id}.xml",
        :headers=>credentials(user)
      assert_response :success
      assert_sla_show_xml(sla)
    end
  end

  test "GET /sla/slas/:id.xml should forbidden for other users" do
    sla = Sla.first
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      get "/sla/slas/#{sla.id}.xml",
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end

  test "GET /sla/slas/:id.xml should forbidden withtout credentials" do
    sla = Sla.first
    get "/sla/slas/#{sla.id}.xml'"
    assert_response :unauthorized
  end   

  # Sla#show in JSON

  test "GET /sla/slas/:id.json should success for admin" do
    sla = Sla.first
    ['admin'].each do |user|
      get "/sla/slas/#{sla.id}.json",
        :headers => credentials(user)
      assert_response :success
      assert_sla_show_json(sla)
    end
  end

  test "GET /sla/slas/:id.json should forbidden for other users" do
    sla = Sla.first
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      get "/sla/slas/#{sla.id}.json",
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end
 
  test "GET /sla/slas/:id.json should forbidden withtout credentials" do
    sla = Sla.first
    get "/sla/slas/#{sla.id}.json"
    assert_response :unauthorized
  end  

  # Sla#create in XML

  test "POST /sla/slas.xml with blank parameters should return errors" do
    assert_no_difference('Sla.count') do
      post "/sla/slas.xml",
        :params => {:sla => {:name => ''}},
        :headers => credentials('admin')
    end
    assert_response :unprocessable_entity
    assert_equal 'application/xml', @response.media_type
    assert_select 'errors error', :text => "Name cannot be blank"
  end

  test "POST /sla/slas.xml with invalid parameters should return errors" do
    sla = Sla.first
    assert_no_difference('Sla.count') do
      post "/sla/slas.xml",
        :params => {:sla => {:name => sla.name}},
        :headers => credentials('admin')
    end
    assert_response :unprocessable_entity
    assert_equal 'application/xml', @response.media_type
    assert_select 'errors error', :text => "Name has already been taken"
  end

  test "POST /sla/slas.xml with valid parameters should return success" do
    assert_difference('Sla.count',1) do
      post "/sla/slas.xml",
        :params => {:sla => {:name => 'API Test'}},
        :headers => credentials('admin')
    end
    assert_response :success
    assert_equal 'application/xml', @response.media_type
  end

  test "POST /sla/slas.xml should forbidden the sla" do
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      post "/sla/slas.xml",
        :params => {:sla => {:name => 'API Test'}},
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end
 
  test "POST /sla/slas.xml should unauthorized the sla withtout credentials" do
    post "/sla/slas.xml",
      :params => {:sla => {:name => 'API Test'}}
    assert_response :unauthorized
  end      

  # Sla#update in XML

  test "PUT /sla/slas/:id.xml with blank parameters should unprocessable_entity for admin" do
    sla = Sla.first
    assert_no_difference('Sla.count') do
      put "/sla/slas/#{sla.id}.xml",
        :params => {:sla => {:name => ''}},
        :headers => credentials('admin')
    end
    assert_response :unprocessable_entity
    assert_equal 'application/xml', @response.media_type
    assert_select 'errors', :text => "Name cannot be blank"
  end  

  test "PUT /sla/slas/:id.xml with invalid parameters should unprocessable_entity for admin" do
    sla = Sla.first
    sla_last = Sla.last
    assert_no_difference('Sla.count') do
      put "/sla/slas/#{sla.id}.xml",
        :params => {:sla => {:name => sla_last.name}},
        :headers => credentials('admin')
    end
    assert_response :unprocessable_entity
    assert_equal 'application/xml', @response.media_type
    assert_select 'errors', :text => "Name has already been taken"
  end

  test "PUT /sla/slas/:id.xml with valid parameters should update the sla" do
    sla = Sla.first
    assert_no_difference 'Sla.count' do
      put "/sla/slas/#{sla.id}.xml",
        :params => {:sla => {:name => 'API update'}},
        :headers => credentials('admin')
    end
    assert_response :no_content
    assert_equal '', @response.body
    assert_nil @response.media_type
    sla = Sla.find(sla.id)
    assert_equal 'API update', sla.name
  end

  test "PUT /sla/slas/:id.xml should forbidden for other users" do
    sla = Sla.first
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      put "/sla/slas/#{sla.id}.xml",
        :params => {:sla => {:name => 'API Test'}},
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end
 
  test "PUT /sla/slas/:id.xml should unauthorized withtout credentials" do
    sla = Sla.first
    put "/sla/slas/#{sla.id}.xml",
      :params => {:sla => {:name => 'API Test'}}
    assert_response :unauthorized
  end  

  # Sla#destroy in XML

  test "DELETE /sla/slas/:id.xml should deletion of the sla" do
    sla = Sla.generate!
    sla_id = sla.id
    assert_difference('Sla.count',-1) do
      delete "/sla/slas/#{sla_id}.xml",
        :headers => credentials('admin')
    end
    assert_response :no_content
    assert_equal '', @response.body
    assert_nil Sla.find_by(id: sla_id)
  end

  test "DELETE /sla/slas/:id.xml should forbidden the sla for other users" do
    sla = Sla.generate!
    sla_id = sla.id
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      delete "/sla/slas/#{sla_id}.xml",
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end
 
  test "DELETE /sla/slas/:id.json should unauthorized the sla withtout credentials" do
    sla = Sla.generate!
    sla_id = sla.id
    delete "/sla/slas/#{sla_id}.xml"
    assert_response :unauthorized
  end    

  private

  def assert_sla_show_xml(sla)
    assert_equal 'application/xml', @response.media_type
    assert_select 'sla>id', :integer => sla.id
    assert_select 'sla>name', :text => sla.name
  end

  def assert_sla_index_xml(sla,count)
    assert_equal 'application/xml', @response.media_type
    assert_select 'slas' do
      assert_select '[total_count=?]', count
    end    
    assert_select 'slas>sla:last-child' do
      assert_select '>id', :integer => sla.id
      assert_select '>name', :text => sla.name
    end
  end

  def assert_sla_show_json(sla)
    assert_equal 'application/json', @response.media_type
    json = ActiveSupport::JSON.decode(response.body)
    assert_kind_of Hash, json
    assert_kind_of Hash, json['sla']
    assert_equal sla.id, json['sla']['id']
    assert_equal sla.name, json['sla']['name']
  end

  def assert_sla_index_json(sla,count)
    assert_equal 'application/json', @response.media_type
    json = ActiveSupport::JSON.decode(response.body)
    assert_kind_of Hash, json
    assert_kind_of Array, json['slas']
    assert_kind_of Hash, json['slas'].last
    assert json['slas'].last.has_key?('id')
    assert json['slas'].last.has_key?('name')
    assert_equal(sla.id, json['slas'].last['id'])
    assert_equal(sla.name, json['slas'].last['name'])
    assert_equal(count, json['total_count'])
  end


end