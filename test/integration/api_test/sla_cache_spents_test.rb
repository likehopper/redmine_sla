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

require_relative "../../helpers/sla_caches_helper"
require_relative "../../test_helper"

class Redmine::ApiTest::SlaCacheSpentsTest < Redmine::ApiTest::Base
  include ActiveJob::TestHelper
  include SlaCachesHelperTest

  item_project_sla_tests_tma = 17
  item_project_sla_tests_std = 82
  item_project_sla_tests_spe1 = 16
  item_project_sla_tests_tma_cf	= 19

  item_for_all = item_project_sla_tests_tma + item_project_sla_tests_std + item_project_sla_tests_spe1 + item_project_sla_tests_tma_cf
  
  item_for_dev = item_project_sla_tests_tma + item_project_sla_tests_tma_cf
  item_for_sys = item_project_sla_tests_std + item_project_sla_tests_spe1

  # Sla#index in XML then JSON

  test "GET /sla/cache_spents.xml should return missing sla_cache_spents manage by project" do
    ['admin','manager'].each do |user|
      sla_cache_spent = SlaCacheSpent.where(project: 1).order(:id).first # project-sla-tests-tma
      get "/projects/project-sla-tests-tma/sla/cache_spents.xml?issue.status_id=*&sort=issue",
        headers: credentials(user)
      assert_response :missing
      sla_cache_spent = SlaCacheSpent.where(project: 2).order(:id).first # project-sla-tests-std
      get "/projects/project-sla-tests-std/sla/cache_spents.xml?issue.status_id=*&order=issue",
        headers: credentials(user)
      assert_response :missing
    end
  end

  test "GET /sla/cache_spents.xml should return sla_cache_spents full" do
    sla_cache_spent = SlaCacheSpent.order(:id).first
    ['admin','manager'].each do |user|
      get "/sla/cache_spents.xml?issue.status_id=*&sort=issue",
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_spent_index_xml(sla_cache_spent,item_for_all)
    end
  end

  test "GET /sla/cache_spents.xml should return sla_cache_spents spent first" do
    sla_cache_spent = SlaCacheSpent.where("sla_cache_spents.spent = 30").order(:id).first
    sla_cache_spent_count = SlaCacheSpent.where("sla_cache_spents.spent = 30").count
    uri = URI("/sla/cache_spents.xml")
    uri.query = URI.encode_www_form("issue.status_id"=>"*", "spent"=>"30")
    ['admin','manager'].each do |user|
      get uri.to_s,
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_spent_index_xml(sla_cache_spent,sla_cache_spent_count)  
    end
  end

  test "GET /sla/cache_spents.xml should return sla_cache_spents spent none" do
    uri = URI("/sla/cache_spents.xml")
    uri.query = URI.encode_www_form("issue.status_id"=>"*", "spent"=>"-12")
    ['admin','manager'].each do |user|
      get uri.to_s,
        headers: credentials(user)
      assert_response :success
      assert_equal 'application/xml', @response.media_type
      assert_select 'sla_cache_spents' do
        assert_select '[total_count=?]', 0
      end
    end
  end  

  test "GET /sla/cache_spents.xml should return sla_cache_spents issue first" do
    sla_cache_spent = SlaCacheSpent.order(:id).first
    ['admin','manager'].each do |user|
      get "/sla/cache_spents.xml?issue.status_id=*&issue_id=#{sla_cache_spent.issue_id}",
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_spent_index_xml(sla_cache_spent,1)  
    end
  end

  test "GET /sla/cache_spents.xml should return sla_cache_spents issue none" do
    sla_cache_spent = SlaCacheSpent.order(:id).first
    ['admin','manager'].each do |user|
      get "/sla/cache_spents.xml?issue_id=#{sla_cache_spent.id}",
        headers: credentials(user)
      assert_response :success
      assert_equal 'application/xml', @response.media_type
      assert_select 'sla_cache_spents' do
        assert_select '[total_count=?]', 0
      end
    end
  end

  test "GET /sla/cache_spents.xml should return sla_cache_spents issue.tracker_id first" do
    sla_cache_spent = SlaCacheSpent.where("issues.tracker_id=1").order(:id).first
    sla_cache_spent_count = SlaCacheSpent.where("issues.tracker_id=1").count
    ['admin','manager'].each do |user|
      get "/sla/cache_spents.xml?issue.status_id=*&issue.tracker_id=1&sort=issue_id",
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_spent_index_xml(sla_cache_spent,sla_cache_spent_count)  
    end
  end

  test "GET /sla/cache_spents.xml should return sla_cache_spents issue.tracker_id none" do
    ['admin','manager'].each do |user|
      get "/sla/cache_spents.xml?issue.tracker_id=1",
        headers: credentials(user)
      assert_response :success
      assert_equal 'application/xml', @response.media_type
      assert_select 'sla_cache_spents' do
        assert_select '[total_count=?]', 0
      end
    end
  end    

  test "GET /sla/cache_spents.xml should return sla_cache_spents sla_level_id first" do
    sla_cache_spent = SlaCacheSpent.where("sla_caches.sla_level_id = 1").order(:id).first
    sla_cache_spent_count = SlaCacheSpent.order(:id).where("sla_caches.sla_level_id = 1").count
    ['admin','manager'].each do |user|
      get "/sla/cache_spents.xml?issue.status_id=*&sla_level_id=1",
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_spent_index_xml(sla_cache_spent,sla_cache_spent_count)  
    end
  end

  test "GET /sla/cache_spents.xml should return success sla_cache_spents sla_level_id none" do
    #sla_cache_spent = SlaCacheSpent.where(sla_level_id: 1).first
    ['admin','manager'].each do |user|
      get "/sla/cache_spents.xml?sla_level_id=99",
        headers: credentials(user)
      assert_response :success
      assert_equal 'application/xml', @response.media_type
      assert_select 'sla_cache_spents' do
        assert_select '[total_count=?]', 0
      end
    end
  end 

  test "GET /sla/cache_spents.json should return missing by project" do
    ['admin','manager'].each { |user|
      sla_cache_spent = SlaCacheSpent.where(project: 1).order(:id).first # project-sla-tests-tma
      get "/projects/project-sla-tests-tma/sla/cache_spents.json?issue.status_id=*&sort=issue",
        headers: credentials(user)
      assert_response :missing
      get "/projects/project-sla-tests-std/sla/cache_spents.json?issue.status_id=*&sort=issue",
        headers: credentials(user)
      assert_response :missing
    }
  end

  test "GET /sla/cache_spents.json should return sla_cache_spents full" do
    sla_cache_spent = SlaCacheSpent.order(:issue_id).first
    ['admin'].each { |user|
      get "/sla/cache_spents.json?issue.status_id=*&sort=issue",
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_spent_index_json(sla_cache_spent,item_for_all)
    }
    ['manager'].each { |user|
      get "/sla/cache_spents.json?issue.status_id=*&sort=issue",
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_spent_index_json(sla_cache_spent,item_for_all)
    }
    sla_cache_spent = SlaCacheSpent.where(project: 1).order(:id).first # project-sla-tests-tma
    ['developer'].each { |user|
      get "/sla/cache_spents.json?issue.status_id=*&sort=issue",
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_spent_index_json(sla_cache_spent,item_for_dev)
    }    
    sla_cache_spent = SlaCacheSpent.where(project: 2).order(:id).first # project-sla-tests-tma
    ['sysadmin'].each { |user|
      get "/sla/cache_spents.json?issue.status_id=*&sort=issue",
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_spent_index_json(sla_cache_spent,item_for_sys)
    }
  end  

  test "GET /sla/cache_spents.xml should return sla_cache_spents partial for developer" do
    ['developer'].each do |user|
      # TODO : issue auquel il a accès trier par ordre id asc ???
      sla_cache_spent = SlaCacheSpent.where(project: 1).order(:id).first # project-sla-tests-tma
      get "/projects/project-sla-tests-tma/sla/cache_spents.xml?issue.status_id=*&sort=issue",
        headers: credentials(user)
      assert_response :missing
      get "/sla/cache_spents.xml?issue.status_id=*&project_id=1", # project-sla-tests-tma
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_spent_index_xml(sla_cache_spent,item_project_sla_tests_tma)
      get "/projects/project-sla-tests-std/sla/cache_spents.xml?issue.status_id=*",
        headers: credentials(user)
      assert_response :missing
      get "/sla/cache_spents.xml?issue.status_id=*&project_id=2", # project-sla-tests-std
        headers: credentials(user)
      assert_response :forbidden
    end
  end

  test "GET /sla/cache_spents.json should return missing|forbidden sla_cache_spents partial for developer" do
    ['developer'].each do |user|
      sla_cache_spent = SlaCacheSpent.where(project: 1).order(:id).first # project-sla-tests-tma
      get "/projects/project-sla-tests-tma/sla/cache_spents.json?issue.status_id=*&sort=issue",
        headers: credentials(user)
      assert_response :missing
      get "/sla/cache_spents.json?issue.status_id=*&project_id=1", # project-sla-tests-tma
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_spent_index_json(sla_cache_spent,item_project_sla_tests_tma)
      get "/projects/project-sla-tests-std/sla/cache_spents.json?issue.status_id=*",
        headers: credentials(user)
      assert_response :missing
      get "/sla/cache_spents.json?issue.status_id=*&project_id=2", # project-sla-tests-std
        headers: credentials(user)
      assert_response :forbidden
    end
  end  

  test "GET /sla/cache_spents.xml should return missing|success|forbidden sla_cache_spents partial for sysadmin" do
    ['sysadmin'].each do |user|
      sla_cache_spent = SlaCacheSpent.order(:id).find_by(project: 2) # project-sla-tests-std
      get "/projects/project-sla-tests-std/sla/cache_spents.xml?issue.status_id=*&sort=issue",
        headers: credentials(user)
      assert_response :missing
      get "/sla/cache_spents.xml?issue.status_id=*&project_id=2", # project-sla-tests-std
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_spent_index_xml(sla_cache_spent,item_project_sla_tests_std)
      get "/projects/project-sla-tests-tma/sla/cache_spents.xml?issue.status_id=*",
        headers: credentials(user)
      assert_response :missing
      get "/sla/cache_spents.xml?issue.status_id=*&project_id=1", # project-sla-tests-tma
        headers: credentials(user)
      assert_response :forbidden
    end
  end

  test "GET /sla/cache_spents.json should return missing|success sla_cache_spents partial for sysadmin" do
    ['sysadmin'].each do |user|
      sla_cache_spent = SlaCacheSpent.where(project: 2).order(:id).first # project-sla-tests-std
      get "/projects/project-sla-tests-std/sla/cache_spents.json?issue.status_id=*", # project-sla-tests-std
        headers: credentials(user)
      assert_response :missing
      get "/sla/cache_spents.json?issue.status_id=*&project_id=2", # project-sla-tests-std
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_spent_index_json(sla_cache_spent,item_project_sla_tests_std)
      get "/projects/project-sla-tests-tma/sla/cache_spents.json?issue.status_id=*", # project-sla-tests-tma
        headers: credentials(user)
      assert_response :missing
      get "/sla/cache_spents.json?issue.status_id=*&project_id=1", # project-sla-tests-tma
        headers: credentials(user)
      assert_response :forbidden
    end
  end  

  test "GET /sla/cache_spents.xml should forbidden the sla cache for tohers" do
    ['reporter','other'].each do |user|
      get "/sla/cache_spents.xml?issue.status_id=*",
        headers: credentials(user)
      assert_response :forbidden
    end
  end

  test "GET /sla/cache_spents.json should forbidden the sla cache for tohers" do
    ['reporter','other'].each { |user|
      get "/sla/cache_spents.json?issue.status_id=*",
        headers: credentials(user)
      assert_response :forbidden
    }
  end  

  test "GET /sla/cache_spents.xml should unauthorized the sla cache withtout credentials" do
      get "/sla/cache_spents.xml?issue.status_id=*"
      assert_response :unauthorized
  end    

  test "GET /sla/cache_spents.json should unauthorized the sla cache withtout credentials" do
    get "/sla/cache_spents.json?issue.status_id=*"
    assert_response :unauthorized
  end


  # Sla#show in XML

  test "GET /sla/cache_spents/:id.xml should return the sla cache tma/dev" do
    sla_cache_spent = SlaCacheSpent.where(project: 1).order(:id).first # project-sla-tests-tma
    ['admin','manager','developer'].each do |user|
      get "/sla/cache_spents/#{sla_cache_spent.id}.xml",
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_spent_show_xml(sla_cache_spent)
    end    
    ['sysadmin'].each do |user|
      get "/sla/cache_spents/#{sla_cache_spent.id}.xml",
        headers: credentials(user)
      assert_response :forbidden
    end
    ['admin','manager','developer'].each do |user|
      get "/projects/project-sla-tests-tma/sla/cache_spents/#{sla_cache_spent.id}.xml",
        headers: credentials(user)
      assert_response :missing
    end
    ['sysadmin'].each do |user|
      get "/projects/project-sla-tests-tma/sla/cache_spents/#{sla_cache_spent.id}.xml",
        headers: credentials(user)
      assert_response :missing
    end
  end

  test "GET /sla/cache_spents/:id.json should return the sla cache for developer" do
    sla_cache_spent = SlaCacheSpent.where(project: 1).order(:issue_id).last # project-sla-tests-tma
    ['admin','manager'].each do |user|
      get "/sla/cache_spents/#{sla_cache_spent.id}.json",
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_spent_show_json(sla_cache_spent)
    end    
    ['developer'].each do |user|
      get "/sla/cache_spents/#{sla_cache_spent.id}.json",
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_spent_show_json(sla_cache_spent)
    end
    ['sysadmin'].each do |user|
      get "/sla/cache_spents/#{sla_cache_spent.id}.json",
        headers: credentials(user)
      assert_response :forbidden
    end
    ['admin','manager'].each do |user|
      get "/projects/project-sla-tests-tma/sla/cache_spents/#{sla_cache_spent.id}.json",
        headers: credentials(user)
      assert_response :missing
    end
    ['developer'].each do |user|
      get "/projects/project-sla-tests-tma/sla/cache_spents/#{sla_cache_spent.id}.json",
        headers: credentials(user)
      assert_response :missing
    end
    ['sysadmin'].each do |user|
      get "/projects/project-sla-tests-tma/sla/cache_spents/#{sla_cache_spent.id}.json",
        headers: credentials(user)
      assert_response :missing
    end    
  end

  test "GET /sla/cache_spents/:id.xml should return success|missing|forbidden the sla cache std/sys" do
    sla_cache_spent = SlaCacheSpent.where(project: 2).order(:id).first # project-sla-tests-std
    ['admin','manager','sysadmin'].each do |user|
      get "/sla/cache_spents/#{sla_cache_spent.id}.xml",
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_spent_show_xml(sla_cache_spent)
    end    
    ['developer'].each do |user|
      get "/sla/cache_spents/#{sla_cache_spent.id}.xml",
        headers: credentials(user)
        assert_response :forbidden
    end
    ['admin','manager','sysadmin'].each do |user|
      get "/projects/project-sla-tests-std/sla/cache_spents/#{sla_cache_spent.id}.xml",
        headers: credentials(user)
      assert_response :missing
    end
    ['developer'].each do |user|
      get "/projects/project-sla-tests-std/sla/cache_spents/#{sla_cache_spent.id}.xml",
        headers: credentials(user)
      assert_response :missing
    end
  end

  test "GET /sla/cache_spents/:id.json should return the sla cache std/sys" do
    sla_cache_spent = SlaCacheSpent.where(project: 2).order(:id).first # project-sla-tests-std
    ['admin','manager'].each do |user|
      get "/sla/cache_spents/#{sla_cache_spent.id}.json",
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_spent_show_json(sla_cache_spent)
    end
    ['developer'].each do |user|
      get "/sla/cache_spents/#{sla_cache_spent.id}.json",
        headers: credentials(user)
      assert_response :forbidden
    end
    ['sysadmin'].each do |user|
      get "/sla/cache_spents/#{sla_cache_spent.id}.json",
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_spent_show_json(sla_cache_spent)
    end
    ['admin','manager'].each do |user|
      get "/projects/project-sla-tests-std/sla/cache_spents/#{sla_cache_spent.id}.json",
        headers: credentials(user)
      assert_response :missing
    end
    ['sysadmin','developer'].each do |user|
      get "/projects/project-sla-tests-std/sla/cache_spents/#{sla_cache_spent.id}.json",
        headers: credentials(user)
      assert_response :missing
    end
  end

  test "GET /sla/cache_spents/:id.xml should missing|forbidden the sla cache for others" do
    sla_cache_spent = SlaCacheSpent.where(project: 1).order(:id).first # project-sla-tests-tma
    ['reporter','other'].each do |user|
      get "/projects/project-sla-tests-tma/sla/cache_spents/#{sla_cache_spent.id}.xml",
        headers: credentials(user)
      assert_response :missing      
      get "/sla/cache_spents/#{sla_cache_spent.id}.xml",
        headers: credentials(user)
      assert_response :forbidden
    end
    sla_cache_spent = SlaCacheSpent.where(project: 2).order(:id).first # project-sla-tests-std
    ['reporter','other'].each do |user|
      get "/projects/project-sla-tests-std/sla/cache_spents/#{sla_cache_spent.id}.xml",
        headers: credentials(user)
      assert_response :missing     
      get "/sla/cache_spents/#{sla_cache_spent.id}.xml",
        headers: credentials(user)
      assert_response :forbidden
    end
  end

  test "GET /sla/cache_spents/:id.json should missing|forbidden the sla cache for others" do
    sla_cache_spent = SlaCacheSpent.where(project: 1).order(:id).first # project-sla-tests-tma
    ['reporter','other'].each do |user|
      get "/projects/project-sla-tests-tma/sla/cache_spents/#{sla_cache_spent.id}.json",
        headers: credentials(user)
      assert_response :missing      
      get "/sla/cache_spents/#{sla_cache_spent.id}.json",
        headers: credentials(user)
      assert_response :forbidden
    end
    sla_cache_spent = SlaCacheSpent.where(project: 2).order(:id).first # project-sla-tests-std
    ['reporter','other'].each do |user|
      get "/projects/project-sla-tests-std/sla/cache_spents/#{sla_cache_spent.id}.json",
        headers: credentials(user)
      assert_response :missing     
      get "/sla/cache_spents/#{sla_cache_spent.id}.json",
        headers: credentials(user)
      assert_response :forbidden
    end
  end  

  test "GET /sla/cache_spents/:id.xml should missing|unauthorized the sla cache withtout credentials" do
    sla_cache_spent = SlaCacheSpent.where(project: 1).order(:id).first # project-sla-tests-tma
    get "/projects/project-sla-tests-tma/sla/cache_spents/#{sla_cache_spent.id}.xml"
    assert_response :missing
    sla = SlaCacheSpent.first
    get "/sla/cache_spents/#{sla_cache_spent.id}.xml"
    assert_response :unauthorized    
    sla_cache_spent = SlaCacheSpent.where(project: 2).order(:id).first # project-sla-tests-tma
    get "/projects/project-sla-tests-std/sla/cache_spents/#{sla_cache_spent.id}.xml"
    assert_response :missing
    sla = SlaCacheSpent.first
    get "/sla/cache_spents/#{sla_cache_spent.id}.xml"
    assert_response :unauthorized      
  end

  test "GET /sla/cache_spents/:id.json should missing|unauthorized the sla cache withtout credentials" do
    sla_cache_spent = SlaCacheSpent.where(project: 1).order(:id).first # project-sla-tests-tma
    get "/projects/project-sla-tests-tma/sla/cache_spents/#{sla_cache_spent.id}.json"
    assert_response :missing
    sla = SlaCacheSpent.first
    get "/sla/cache_spents/#{sla_cache_spent.id}.json"
    assert_response :unauthorized    
    sla_cache_spent = SlaCacheSpent.where(project: 2).order(:id).first # project-sla-tests-tma
    get "/projects/project-sla-tests-std/sla/cache_spents/#{sla_cache_spent.id}.json"
    assert_response :missing
    sla = SlaCacheSpent.first
    get "/sla/cache_spents/#{sla_cache_spent.id}.json"
    assert_response :unauthorized      
  end

  # Sla#refresh in JSON

  test "GET /sla/cache_spents/:id/refresh.json should return missing|success on the sla cache for admin" do
    ['admin'].each do |user|
      sla_cache_spent = SlaCacheSpent.find_by(project: 1) # project-sla-tests-tma
      get "/projects/project-sla-tests-tma/sla/cache_spents/#{sla_cache_spent.id}/refresh.json",
        headers: credentials(user)
      assert_response :missing
      sla_cache_spent = SlaCacheSpent.find_by(project: 2) # project-sla-tests-std
      get "/projects/project-sla-tests-std/sla/cache_spents/#{sla_cache_spent.id}/refresh.json",
        headers: credentials(user)
      assert_response :missing            
      sla_cache_spent = SlaCacheSpent.first
      get "/sla/cache_spents/#{sla_cache_spent.id}/refresh.json",
        headers: credentials(user)
      assert_response :success
    end
  end

  test "GET /sla/cache_spents/:id/refresh.json should return missing on the sla cache for manager" do
    ['manager'].each do |user|
      sla_cache_spent = SlaCacheSpent.find_by(project: 1) # project-sla-tests-tma
      get "/projects/project-sla-tests-tma/sla/cache_spents/#{sla_cache_spent.id}/refresh.json",
        headers: credentials(user)
      assert_response :missing
      sla_cache_spent = SlaCacheSpent.find_by(project: 2) # project-sla-tests-std
      get "/projects/project-sla-tests-std/sla/cache_spents/#{sla_cache_spent.id}/refresh.json",
        headers: credentials(user)
      assert_response :missing            
      sla_cache_spent = SlaCacheSpent.first
      get "/sla/cache_spents/#{sla_cache_spent.id}/refresh.json",
        headers: credentials(user)
      assert_response :success
    end
  end

  test "GET /sla/cache_spents/:id/refresh.json should return forbidden on sla cache for developer" do
    ['developer'].each do |user|
      sla_cache_spent = SlaCacheSpent.find_by(project: 1) # project-sla-tests-tma
      get "/projects/project-sla-tests-tma/sla/cache_spents/#{sla_cache_spent.id}/refresh.json",
        headers: credentials(user)
      assert_response :missing
      get "/projects/project-sla-tests-std/sla/cache_spents/#{sla_cache_spent.id}/refresh.json",
        headers: credentials(user)
      assert_response :missing
      get "/sla/cache_spents/#{sla_cache_spent.id}/refresh.json",
        headers: credentials(user)
      assert_response :success
      sla_cache_spent = SlaCacheSpent.find_by(project: 2) # project-sla-tests-std
      get "/sla/cache_spents/#{sla_cache_spent.id}/refresh.json",
        headers: credentials(user)
      assert_response :forbidden
    end
  end  

  test "GET /sla/cache_spents/:id/refresh.json should return forbidden on sla cache for sysadmin" do
    ['sysadmin'].each do |user|
      sla_cache_spent = SlaCacheSpent.find_by(project: 1) # project-sla-tests-tma
      get "/projects/project-sla-tests-std/sla/cache_spents/#{sla_cache_spent.id}/refresh.json",
        headers: credentials(user)
      assert_response :missing
      get "/projects/project-sla-tests-std/sla/cache_spents/#{sla_cache_spent.id}/refresh.json",
        headers: credentials(user)
      assert_response :missing
      get "/sla/cache_spents/#{sla_cache_spent.id}/refresh.json",
        headers: credentials(user)
      assert_response :forbidden
      sla_cache_spent = SlaCacheSpent.find_by(project: 2) # project-sla-tests-std
      get "/sla/cache_spents/#{sla_cache_spent.id}/refresh.json",
        headers: credentials(user)
      assert_response :success
    end
  end

  test "GET /sla/cache_spents/:id/refresh.json should forbidden the sla cache for others" do
    sla_cache_spent = SlaCacheSpent.first
    ['reporter','other'].each do |user|
      get "/sla/cache_spents/#{sla_cache_spent.id}.json",
        headers: credentials(user)
      assert_response :forbidden
    end
  end
 
  test "GET /sla/cache_spents/:id/refresh.json should unauthorized the sla cache withtout credentials" do
    sla_cache_spent = SlaCacheSpent.first
    get "/sla/cache_spents/#{sla_cache_spent.id}.json"
    assert_response :unauthorized
  end  

  # Sla#create in XML

  test "PUT /sla/cache_spents/:id.xml should missing the sla cache for others users" do
    sla_cache_spent = SlaCacheSpent.find_by(project: 1) # project-sla-tests-tma
    ['admin','manager','developer','sysadmin','reporter','other'].each do |user|
      put "/sla/cache_spents/#{sla_cache_spent.id}.xml",
        params: {sla_cache_spent: {}},
        headers: credentials(user)
      assert_response :missing
    end
    sla_cache_spent = SlaCacheSpent.find_by(project: 2) # project-sla-tests-std
    ['admin','manager','developer','sysadmin','reporter','other'].each do |user|
      put "/sla/cache_spents/#{sla_cache_spent.id}.xml",
        params: {sla_cache_spent: {}},
        headers: credentials(user)
      assert_response :missing
    end
  end
 
  test "PUT /sla/cache_spents/:id.xml should missing the sla cache withtout credentials" do
    sla_cache_spent = SlaCacheSpent.find_by(project: 1) # project-sla-tests-tma
    put "/sla/cache_spents/#{sla_cache_spent.id}.xml",
      params: {sla_cache_spent: {}}
    assert_response :missing
    sla_cache_spent = SlaCacheSpent.find_by(project: 2) # project-sla-tests-std
    put "/sla/cache_spents/#{sla_cache_spent.id}.xml",
      params: {sla_cache_spent: {}}
    assert_response :missing
  end  

  # Sla#destroy in XML

  test "DELETE /sla/cache_spents/:id.xml should missing|success the sla cache for admin" do
    ['admin'].each do |user|
      sla_cache_spent_id = SlaCacheSpent.find_by(project: 1).id # project-sla-tests-tma
      delete "/projects/project-sla-tests-tma/sla/cache_spents/#{sla_cache_spent_id}.xml",
        headers: credentials(user)
      assert_response :missing
      delete "/sla/cache_spents/#{sla_cache_spent_id}.xml",
        headers: credentials(user)
      assert_response :success
      renew_issue(sla_cache_spent_id)
      sla_cache_spent_id = SlaCacheSpent.find_by(project: 2).id # project-sla-tests-std
      delete "/projects/project-sla-tests-std/sla/cache_spents/#{sla_cache_spent_id}.xml",
        headers: credentials(user)
      assert_response :missing
      delete "/sla/cache_spents/#{sla_cache_spent_id}.xml",
        headers: credentials(user)
      assert_response :success
      renew_issue(sla_cache_spent_id)
    end
  end

  test "DELETE /sla/cache_spents/:id.xml should missing|success the sla cache for manager" do
    ['manager'].each do |user|
      sla_cache_spent_id = SlaCacheSpent.find_by(project: 1).id # project-sla-tests-tma
      delete "/projects/project-sla-tests-tma/sla/cache_spents/#{sla_cache_spent_id}.xml",
        headers: credentials(user)
      assert_response :missing
      delete "/sla/cache_spents/#{sla_cache_spent_id}.xml",
        headers: credentials(user)
      assert_response :success
      renew_issue(sla_cache_spent_id)
      sla_cache_spent_id = SlaCacheSpent.find_by(project: 2).id # project-sla-tests-std
      delete "/projects/project-sla-tests-std/sla/cache_spents/#{sla_cache_spent_id}.xml",
        headers: credentials(user)
      assert_response :missing
      delete "/sla/cache_spents/#{sla_cache_spent_id}.xml",
        headers: credentials(user)
      assert_response :success
      renew_issue(sla_cache_spent_id)
    end
  end

  test "DELETE /sla/cache_spents/:id.xml should unauthorized the sla cache for others users" do
    ['reporter','other'].each do |user|
      sla_cache_spent = SlaCacheSpent.find_by(project: 1) # project-sla-tests-tma
      delete "/sla/cache_spents/#{sla_cache_spent.id}.xml",
        headers: credentials(user)
      assert_response :forbidden
    end
    ['reporter','other'].each do |user|
      sla_cache_spent = SlaCacheSpent.find_by(project: 2) # project-sla-tests-std
      delete "/sla/cache_spents/#{sla_cache_spent.id}.xml",
        headers: credentials(user)
      assert_response :forbidden
    end
  end  
 
  test "DELETE /sla/cache_spents/:id.json should unauthorized the sla cache withtout credentials" do
    sla_cache_spent = SlaCacheSpent.find_by(project: 1) # project-sla-tests-tma
    delete "/sla/cache_spents/#{sla_cache_spent.id}.xml"
    assert_response :unauthorized    
    sla_cache_spent = SlaCacheSpent.find_by(project: 2) # project-sla-tests-std
    delete "/sla/cache_spents/#{sla_cache_spent.id}.xml"
    assert_response :unauthorized
  end    


  # TODO : Sla Caches Test +purge
  # TODO : Sla Caches Test +refresh

  private

  def assert_sla_cache_spent_show_xml(sla_cache_spent)
    assert_equal 'application/xml', @response.media_type
    assert_select 'sla_cache_spent>id', integer: sla_cache_spent.id
    assert_select 'sla_cache_spent>issue_id', integer: sla_cache_spent.issue_id
    assert_select 'sla_cache_spent>project_id', integer: sla_cache_spent.project_id
    assert_select 'sla_cache_spent>spent', integer: sla_cache_spent.spent
  end

  def assert_sla_cache_spent_index_xml(sla_cache_spent,count)
    assert_equal 'application/xml', @response.media_type
    assert_select 'sla_cache_spents' do
      assert_select '[total_count=?]', count
    end
    assert_select 'sla_cache_spents>sla_cache_spent:first-child' do
      assert_select '>id', integer: sla_cache_spent.id
      assert_select '>issue_id', integer: sla_cache_spent.issue_id
      assert_select '>project_id', integer: sla_cache_spent.project_id
      assert_select '>spent', integer: sla_cache_spent.spent
    end
  end

  def assert_sla_cache_spent_show_json(sla_cache_spent)
    assert_equal 'application/json', @response.media_type
    json = ActiveSupport::JSON.decode(response.body)
    assert_kind_of Hash, json
    assert_kind_of Hash, json['sla_cache_spent']
    assert_equal sla_cache_spent.id, json['sla_cache_spent']['id']
    assert_equal sla_cache_spent.issue_id, json['sla_cache_spent']['issue_id']
    assert_equal sla_cache_spent.project_id, json['sla_cache_spent']['project_id']
    assert_equal sla_cache_spent.sla_cache_id, json['sla_cache_spent']['sla_cache']['id']
    assert_equal sla_cache_spent.sla_type_id, json['sla_cache_spent']['sla_type']['id']
    assert_equal sla_cache_spent.spent, json['sla_cache_spent']['spent']
  end

  def assert_sla_cache_spent_index_json(sla_cache_spent,count)
    assert_equal 'application/json', @response.media_type
    json = ActiveSupport::JSON.decode(response.body)
    assert_kind_of Hash, json
    assert_kind_of Array, json['sla_cache_spents']
    assert_kind_of Hash, json['sla_cache_spents'].first
    assert json['sla_cache_spents'].first.has_key?('id')
    assert json['sla_cache_spents'].first.has_key?('issue_id')
    assert json['sla_cache_spents'].first.has_key?('project_id') 
    assert json['sla_cache_spents'].first.has_key?('sla_cache_id')
    assert json['sla_cache_spents'].first.has_key?('sla_type_id')
    assert json['sla_cache_spents'].first.has_key?('spent')
    assert_equal(sla_cache_spent.id, json['sla_cache_spents'].first['id'])
    assert_equal(sla_cache_spent.issue_id, json['sla_cache_spents'].first['issue_id'])
    assert_equal(sla_cache_spent.project_id, json['sla_cache_spents'].first['project_id'])
    assert_equal(sla_cache_spent.sla_cache_id, json['sla_cache_spents'].first['sla_cache_id'])
    assert_equal(sla_cache_spent.sla_type_id, json['sla_cache_spents'].first['sla_type_id'])
    assert_equal(sla_cache_spent.spent, json['sla_cache_spents'].first['spent'])
    assert_equal(count, json['total_count'])
  end

end