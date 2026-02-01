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

class Redmine::ApiTest::SlaProjectTrackersTest < ApplicationSlaApiTestCase
  include ActiveJob::TestHelper

  # SlaProjectTracker#index in XML

  test "GET /projects/project-sla-tests-tma/sla/trackers.xml should success for admin" do
    sla_project_tracker = SlaProjectTracker.where(project: 1).order(:id).first
    count = SlaProjectTracker.where(project: 1).order(:id).count
    ['admin'].each do |user|
      get "/projects/project-sla-tests-tma/sla/trackers.xml",
        :headers=>credentials(user)
      assert_response :success
      assert_sla_project_trackers_index_xml(sla_project_tracker,count)
    end
  end

  test "GET /sla/project_trackers.xml?project_id=5 without sla should success for admin" do
    sla_project_tracker = SlaProjectTracker.where(project: 1).order(:id).first
    count = SlaProjectTracker.where(project: 1).order(:id).count
    ['admin'].each do |user|
      get "/sla/project_trackers.xml?project_id=1",
        :headers=>credentials(user)
      assert_response :success
      assert_sla_project_trackers_index_xml(sla_project_tracker,count)
    end
  end  

  test "GET /projects/another-project-without-sla/sla/trackers.xml without module sla should forbidden for all" do
    project = Project.find("another-project-without-sla")
    ['admin','manager','developer','sysadmin','reporter','other'].each do |user|
      get "/sla/project_trackers.xml?project_id=#{project.id}",
        :headers=>credentials(user)
      assert_response :forbidden
    end    
  end

  test "GET /sla/project_trackers.xml?project_id=5 without module sla should forbidden for admin" do
    ['admin','manager','developer','sysadmin','reporter','other'].each do |user|
      get "/sla/project_trackers.xml?project_id=5",
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end

  test "GET /sla/project_trackers.xml without project should success for admin and manager" do
    sla_project_tracker = SlaProjectTracker.first
    count = SlaProjectTracker.count
    ['admin','manager'].each do |user|
      get "/sla/project_trackers.xml",
        :headers=>credentials(user)
      assert_response :success
      assert_sla_project_trackers_index_xml(sla_project_tracker,count)
    end
  end

  test "GET /sla/project_trackers.xml with project should forbidden for other users" do
    ['developer','sysadmin','reporter','other'].each do |user|
      for project_id in 1..5
        get "/sla/project_trackers.xml",
          :headers=>credentials(user)
        assert_response :forbidden
      end
    end
  end

  test "GET /sla/project_trackers.xml should unauthorized withtout credentials" do
    for project_id in 1..5
      get "/sla/project_trackers.xml?project_id=#{project_id}"
      assert_response :unauthorized
    end
    get "/sla/project_trackers.xml"
    assert_response :unauthorized
  end    

  # SlaProjectTracker#index in JSON

  test "GET /projects/project-sla-tests-tma/sla/trackers.json should success for admin" do
    sla_project_tracker = SlaProjectTracker.where(project: 1).order(:id).first
    count = SlaProjectTracker.where(project: 1).order(:id).count
    ['admin'].each do |user|
      get "/projects/project-sla-tests-tma/sla/trackers.json",
        :headers => credentials(user)
      assert_response :success
      assert_sla_project_trackers_index_json(sla_project_tracker,count)
    end
  end  

  test "GET /sla/project_trackers.json should success for admin" do
    sla_project_tracker = SlaProjectTracker.first
    count = SlaProjectTracker.count
    ['admin'].each do |user|
      get "/sla/project_trackers.json",
        :headers => credentials(user)
      assert_response :success
      assert_sla_project_trackers_index_json(sla_project_tracker,count)
    end
  end

  test "GET /sla/project_trackers.json should forbidden for other users" do
    ['developer','sysadmin','reporter','other'].each do |user|
      get "/sla/project_trackers.json",
        :headers => credentials(user)
      assert_response :forbidden
    end
  end

  test "GET /sla/project_trackers.json should unauthorized withtout credentials" do
      get "/sla/project_trackers.json"
      assert_response :unauthorized
  end   

  # SlaProjectTracker#show in XML

  test "GET /sla/project_trackers/:id.xml should missing for admin and manager" do
    sla_project_tracker = SlaProjectTracker.first
    ['admin','manager'].each do |user|
      get "/sla/project_trackers/#{sla_project_tracker.id}.xml",
        :headers=>credentials(user)
      assert_response :missing
    end
  end

  test "GET /sla/project_trackers/:id.xml should missing for other users" do
    sla_project_tracker = SlaProjectTracker.first
    ['developer','sysadmin','reporter','other'].each do |user|
      get "/sla/project_trackers/#{sla_project_tracker.id}.xml",
        :headers=>credentials(user)
      assert_response :missing
    end
  end

  test "GET /sla/project_trackers/:id.xml should missing withtout credentials" do
    sla_project_tracker = SlaProjectTracker.first
    get "/sla/project_trackers/#{sla_project_tracker.id}.xml"
    assert_response :missing
  end   

  # SlaProjectTracker#show in JSON

  test "GET /sla/project_trackers/:id.json should missing for admin" do
    sla_project_tracker = SlaProjectTracker.first
    ['admin'].each do |user|
      get "/sla/project_trackers/#{sla_project_tracker.id}.json",
        :headers => credentials(user)
      assert_response :missing
    end
  end

  test "GET /sla/project_trackers/:id.json should missing for ohter users" do
    sla_project_tracker = SlaProjectTracker.first
    ['manager','developer','sysadmin','reporter','other'].each do |user|
      get "/sla/project_trackers/#{sla_project_tracker.id}.json",
        :headers=>credentials(user)
      assert_response :missing
    end
  end
 
  test "GET /sla/project_trackers/:id.json should missing withtout credentials" do
    sla_project_tracker = SlaProjectTracker.first
    get "/sla/project_trackers/#{sla_project_tracker.id}.json"
    assert_response :missing
  end  

  # SlaProjectTracker#create in XML

  # test "POST /sla/project_trackers.xml with blank parameters should unprocessable_entity for admin" do
  #   assert_no_difference('SlaProjectTracker.count') do
  #     post "/sla/project_trackers.xml",
  #       :params => {:sla_project_tracker => {:name => ''}},
  #       :headers => credentials('admin')
  #   end
  #   assert_response :unprocessable_entity
  #   assert_equal 'application/xml', @response.media_type
  #   assert_select 'errors error', :text => "Name cannot be blank"
  # end

  # test "POST /sla/project_trackers.xml with invalid parameters should unprocessable_entity for admin" do
  #   sla_project_tracker = SlaProjectTracker.first
  #   assert_no_difference('SlaProjectTracker.count') do
  #     post "/sla/project_trackers.xml",
  #       :params => {:sla_project_tracker => {:name => sla_project_tracker.name}},
  #       :headers => credentials('admin')
  #   end
  #   assert_response :unprocessable_entity
  #   assert_equal 'application/xml', @response.media_type
  #   assert_select 'errors error', :text => "Name has already been taken"
  # end

  test "POST /sla/project_trackers.xml with valid parameters should success for admin and manager" do
    ['admin','manager'].each do |user|
      tracker = Tracker.generate!
      sla = Sla.generate!
      assert_difference('SlaProjectTracker.count',1) do
        post "/sla/project_trackers.xml",
          :params => {:sla_project_tracker => {
            :project_id => 1,
            :tracker_id => tracker.id,
            :sla_id => sla.id,
          }},
          :headers => credentials(user)
      end
      assert_response :success
      assert_equal 'application/xml', @response.media_type
      assert_select 'sla_project_tracker>tracker', :integer => tracker.name
      assert_select 'sla_project_tracker>sla', :integer => sla.name
      assert_select 'sla_project_tracker>id' do |element|
        SlaProjectTracker.find(element.text.to_i).delete
      end
    end
  end

  test "POST /projects/project-sla-tests-tma/sla/trackers.xml with valid parameters should success for admin and manager" do
    ['admin','manager'].each do |user|
      tracker = Tracker.generate!
      sla = Sla.generate!
      assert_difference('SlaProjectTracker.where(project_id: 1).count',1) do
        post "/projects/project-sla-tests-tma/sla/trackers.xml",
          :params => {:sla_project_tracker => {
            :tracker_id => tracker.id,
            :sla_id => sla.id,
          }},
          :headers => credentials(user)
      end
      assert_response :success
      assert_equal 'application/xml', @response.media_type
      assert_select 'sla_project_tracker>tracker', :integer => tracker.name
      assert_select 'sla_project_tracker>sla', :integer => sla.name
      assert_select 'sla_project_tracker>id' do |element|
        SlaProjectTracker.find(element.text.to_i).delete
      end
    end
  end

  test "POST /sla/project_trackers.xml should forbidden for other users" do
    tracker = Tracker.generate!
    sla = Sla.generate!
    ['developer','sysadmin','reporter','other'].each do |user|
      post "/sla/project_trackers.xml",
        :params => {:sla_project_tracker => {
          :project_id => 1,
          :tracker_id => tracker.id,
          :sla_id => sla.id,
        }},
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end
 
  test "POST /sla/project_trackers.xml should unauthorized withtout credentials" do
    tracker = Tracker.generate!
    sla = Sla.generate!
    post "/sla/project_trackers.xml",
      :params => {:sla_project_tracker => {
        :project_id => 1,
        :tracker_id => tracker.id,
        :sla_id => sla.id,
      }}
    assert_response :unauthorized
  end      

  # SlaProjectTracker#update in XML

  # test "PUT /sla/project_trackers/:id.xml with blank parameters should unprocessable_entity for admin" do
  #   sla_project_tracker = SlaProjectTracker.first
  #   assert_no_difference('SlaProjectTracker.count') do
  #     put "/sla/project_trackers/#{sla_project_tracker.id}.xml",
  #       :params => {:sla_project_tracker => {:name => ''}},
  #       :headers => credentials('admin')
  #   end
  #   assert_response :unprocessable_entity
  #   assert_equal 'application/xml', @response.media_type
  #   assert_select 'errors', :text => "Name cannot be blank"
  # end

  # test "PUT /sla/project_trackers/:id.xml with invalid parameters should unprocessable_entity for admin" do
  #   sla_project_tracker = SlaProjectTracker.first
  #   sla_project_tracker_last = SlaProjectTracker.last
  #   assert_no_difference('SlaProjectTracker.count') do
  #     put "/sla/project_trackers/#{sla_project_tracker.id}.xml",
  #       :params => {:sla_project_tracker => {:name => sla_project_tracker_last.name}},
  #       :headers => credentials('admin')
  #   end
  #   assert_response :unprocessable_entity
  #   assert_equal 'application/xml', @response.media_type
  #   assert_select 'errors', :text => "Name has already been taken"
  # end

  test "PUT /sla/project_trackers/:id.xml with valid parameters should update the sla_project_tracker" do
    ['admin','manager'].each do |user|
      sla_project_tracker = SlaProjectTracker.generate!(project_id: 1)
      tracker = Tracker.generate!
      sla = Sla.generate!
      assert_no_difference 'SlaProjectTracker.count' do
        put "/sla/project_trackers/#{sla_project_tracker.id}.xml",
          :params => {:sla_project_tracker => {
            :project_id => 1,
            :tracker_id => tracker.id,
            :sla_id => sla.id,
          }},
          :headers => credentials(user)
      end
      assert_response :no_content
      assert_equal '', @response.body
      assert_nil @response.media_type
      sla_project_tracker = SlaProjectTracker.find(sla_project_tracker.id)
      assert_equal 1, sla_project_tracker.project_id
      assert_equal tracker.id, sla_project_tracker.tracker_id
      assert_equal sla.id, sla_project_tracker.sla_id
      sla_project_tracker.delete
    end
  end

  test "PUT /sla/project_trackers/:id.xml should forbidden for other users" do
    sla_project_tracker = SlaProjectTracker.first
    tracker = Tracker.generate!
    sla = Sla.generate!
    ['developer','sysadmin','reporter','other'].each do |user|
      put "/sla/project_trackers/#{sla_project_tracker.id}.xml",
        :params => {:sla_project_tracker => {
          :project_id => 1,
          :tracker_id => tracker.id,
          :sla_id => sla.id,
        }},
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end
 
  test "PUT /sla/project_trackers/:id.xml should unauthorized withtout credentials" do
    sla_project_tracker = SlaProjectTracker.first
    tracker = Tracker.generate!
    sla = Sla.generate!
    put "/sla/project_trackers/#{sla_project_tracker.id}.xml",
      :params => {:sla_project_tracker => {
        :project_id => 1,
        :tracker_id => tracker.id,
        :sla_id => sla.id,
      }}
    assert_response :unauthorized
  end  

  # SlaProjectTracker#destroy in XML

  test "DELETE /sla/project_trackers/:id.xml should success for manager and admin" do
    ['admin','manager'].each do |user|
      sla_project_tracker = SlaProjectTracker.generate!
      sla_project_tracker_id = sla_project_tracker.id
      assert_difference('SlaProjectTracker.count',-1) do
        delete "/sla/project_trackers/#{sla_project_tracker_id}.xml",
          :headers => credentials(user)
      end
      assert_response :no_content
      assert_equal '', @response.body
      assert_nil SlaProjectTracker.find_by(id: sla_project_tracker_id)
    end
  end

  test "DELETE /sla/project_trackers/:id.xml should forbidden for other users" do
    sla_project_tracker = SlaProjectTracker.generate!
    sla_project_tracker_id = sla_project_tracker.id
    ['developer','sysadmin','reporter','other'].each do |user|
      delete "/sla/project_trackers/#{sla_project_tracker_id}.xml",
        :headers=>credentials(user)
      assert_response :forbidden
    end
  end
 
  test "DELETE /sla/project_trackers/:id.json should unauthorized withtout credentials" do
    sla_project_tracker = SlaProjectTracker.generate!
    sla_project_tracker_id = sla_project_tracker.id
    delete "/sla/project_trackers/#{sla_project_tracker_id}.xml"
    assert_response :unauthorized
  end    

  private

  def assert_sla_project_tracker_show_xml(sla_project_tracker)
    assert_equal 'application/xml', @response.media_type
    assert_select 'sla_project_tracker>id', :integer => sla_project_tracker.id
    assert_select 'sla_project_tracker>project_id', :integer => sla_project_tracker.project_id
    assert_select 'sla_project_tracker>tracker_id', :integer => sla_project_tracker.tracker_id
    assert_select 'sla_project_tracker>sla_id', :integer => sla_project_tracker.sla_id
  end

  def assert_sla_project_trackers_index_xml(sla_project_tracker,count)
    assert_equal 'application/xml', @response.media_type
    assert_select 'sla_project_trackers' do
      assert_select '[total_count=?]', count
    end    
    assert_select 'sla_project_trackers>sla_project_tracker:first-child' do
      assert_select '>id', :integer => sla_project_tracker.id
      assert_select '>project_id', :integer => sla_project_tracker.project_id
      assert_select '>tracker_id', :integer => sla_project_tracker.tracker_id
      assert_select '>sla_id', :integer => sla_project_tracker.sla_id
    end
  end

  def assert_sla_project_tracker_show_json(sla_project_tracker)
    assert_equal 'application/json', @response.media_type
    json = ActiveSupport::JSON.decode(response.body)
    assert_kind_of Hash, json
    assert_kind_of Hash, json['sla_project_tracker']
    assert_equal sla_project_tracker.id, json['sla_project_tracker']['id']
    assert_equal sla_project_tracker.project_id, json['sla_project_tracker']['project_id']
    assert_equal sla_project_tracker.tracker_id, json['sla_project_tracker']['tracker_id']
    assert_equal sla_project_tracker.sla_id, json['sla_project_tracker']['sla_id']
  end

  def assert_sla_project_trackers_index_json(sla_project_tracker,count)
    assert_equal 'application/json', @response.media_type
    json = ActiveSupport::JSON.decode(response.body)
    assert_kind_of Hash, json
    assert_kind_of Array, json['sla_project_trackers']
    assert_kind_of Hash, json['sla_project_trackers'].first
    assert json['sla_project_trackers'].first.has_key?('id')
    assert json['sla_project_trackers'].first.has_key?('project_id')
    assert json['sla_project_trackers'].first.has_key?('tracker_id')
    assert json['sla_project_trackers'].first.has_key?('sla_id')
    assert_equal(sla_project_tracker.id, json['sla_project_trackers'].first['id'])
    assert_equal(sla_project_tracker.project_id, json['sla_project_trackers'].first['project_id'])
    assert_equal(sla_project_tracker.tracker_id, json['sla_project_trackers'].first['tracker_id'])
    assert_equal(sla_project_tracker.sla_id, json['sla_project_trackers'].first['sla_id'])
    assert_equal(count, json['total_count'])
  end

end