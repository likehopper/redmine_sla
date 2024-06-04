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

class Redmine::ApiTest::SlaCachesTest < Redmine::ApiTest::Base
  include ActiveJob::TestHelper
  include SlaCachesHelperTest

  issues_in_tma = 10 # project-sla-tests-tma
  issues_in_std = 41 # project-sla-tests-std
  issues_for_dev = 21
  issues_for_sys = 49

  # Sla#index in XML then JSON

  test "GET /sla/caches.xml should return sla_caches manage by project" do
    ['admin','manager'].each do |user|
      sla_cache = SlaCache.where(project: 1).order(:id).first # project-sla-tests-tma
      get "/projects/project-sla-tests-tma/sla/caches.xml?issue.status_id=*&order=id",
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_index_xml(sla_cache,issues_in_tma)
      sla_cache = SlaCache.where(project: 2).order(:id).first # project-sla-tests-std
      get "/projects/project-sla-tests-std/sla/caches.xml?issue.status_id=*&order=id",
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_index_xml(sla_cache,issues_in_std)
    end
  end

  test "GET /sla/caches.xml should return sla_caches full" do
    sla_cache = SlaCache.order(:id).first
    ['admin','manager'].each do |user|
      get "/sla/caches.xml?issue.status_id=*&sort=id",
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_index_xml(sla_cache,issues_for_dev+issues_for_sys)  
    end
  end

  test "GET /sla/caches.json should return manage by project" do
    ['admin','manager'].each { |user|
      sla_cache = SlaCache.where(project: 1).order(:id).first # project-sla-tests-tma
      get "/projects/project-sla-tests-tma/sla/caches.json?issue.status_id=*&order=id",
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_index_json(sla_cache,issues_in_tma)
      sla_cache = SlaCache.where(project: 2).order(:id).first # project-sla-tests-std
      get "/projects/project-sla-tests-std/sla/caches.json?issue.status_id=*&order=id",
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_index_json(sla_cache,issues_in_std)  
    }
  end

  test "GET /sla/caches.json should return sla_caches full" do
    sla_cache = SlaCache.order(:id).first
    ['admin'].each { |user|
      get "/sla/caches.json?issue.status_id=*&sort=id",
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_index_json(sla_cache,issues_for_dev+issues_for_sys)
    }
    ['manager'].each { |user|
      get "/sla/caches.json?issue.status_id=*&sort=id",
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_index_json(sla_cache,issues_for_dev+issues_for_sys)
    }
    sla_cache = SlaCache.where(project: 1).order(:id).first # project-sla-tests-tma
    ['developer'].each { |user|
      get "/sla/caches.json?issue.status_id=*&sort=id",
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_index_json(sla_cache,issues_for_dev)
    }    
    sla_cache = SlaCache.where(project: 2).order(:id).first # project-sla-tests-tma
    ['sysadmin'].each { |user|
      get "/sla/caches.json?issue.status_id=*&sort=id",
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_index_json(sla_cache,issues_for_sys)
    }
  end  

  test "GET /sla/caches.xml should return sla_caches partial for developer" do
    ['developer'].each do |user|
      # TODO : issue auquel il a accès trier par ordre id asc ???
      sla_cache = SlaCache.where(project: 1).order(:id).first # project-sla-tests-tma
      get "/projects/project-sla-tests-tma/sla/caches.xml?issue.status_id=*&order=id",
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_index_xml(sla_cache,issues_in_tma)
      get "/sla/caches.xml?issue.status_id=*&project_id=1", # project-sla-tests-tma
        headers: credentials(user)
      assert_response :success     
      assert_sla_cache_index_xml(sla_cache,issues_in_tma)
      get "/projects/project-sla-tests-std/sla/caches.xml?issue.status_id=*",
        headers: credentials(user)
      assert_response :forbidden
      get "/sla/caches.xml?issue.status_id=*&project_id=2", # project-sla-tests-std
        headers: credentials(user)
      assert_response :forbidden
    end
  end

  test "GET /sla/caches.json should return sla_caches partial for developer" do
    ['developer'].each do |user|
      sla_cache = SlaCache.where(project: 1).order(:id).first # project-sla-tests-tma
      get "/projects/project-sla-tests-tma/sla/caches.json?issue.status_id=*&order=id",
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_index_json(sla_cache,issues_in_tma)
      get "/sla/caches.json?issue.status_id=*&project_id=1", # project-sla-tests-tma
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_index_json(sla_cache,issues_in_tma)      
      get "/projects/project-sla-tests-std/sla/caches.json?issue.status_id=*",
        headers: credentials(user)
      assert_response :forbidden
      get "/sla/caches.json?issue.status_id=*&project_id=2", # project-sla-tests-std
        headers: credentials(user)
      assert_response :forbidden
    end
  end  

  test "GET /sla/caches.xml should return sla_caches partial for sysadmin" do
    ['sysadmin'].each do |user|
      sla_cache = SlaCache.order(:id).find_by(project: 2) # project-sla-tests-std
      get "/projects/project-sla-tests-std/sla/caches.xml?issue.status_id=*&order=id",
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_index_xml(sla_cache,issues_in_std)
      get "/sla/caches.xml?issue.status_id=*&project_id=2", # project-sla-tests-std
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_index_xml(sla_cache,issues_in_std)
      get "/projects/project-sla-tests-tma/sla/caches.xml?issue.status_id=*",
        headers: credentials(user)
      assert_response :forbidden
      get "/sla/caches.xml?issue.status_id=*&project_id=1", # project-sla-tests-tma
        headers: credentials(user)
      assert_response :forbidden
    end
  end

  test "GET /sla/caches.json should return sla_caches partial for sysadmin" do
    ['sysadmin'].each do |user|
      sla_cache = SlaCache.where(project: 2).order(:id).first # project-sla-tests-std
      get "/projects/project-sla-tests-std/sla/caches.json?issue.status_id=*", # project-sla-tests-std
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_index_json(sla_cache,issues_in_std)
      get "/sla/caches.json?issue.status_id=*&project_id=2", # project-sla-tests-std
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_index_json(sla_cache,issues_in_std)
      get "/projects/project-sla-tests-tma/sla/caches.json?issue.status_id=*", # project-sla-tests-tma
        headers: credentials(user)
      assert_response :forbidden
      get "/sla/caches.json?issue.status_id=*&project_id=1", # project-sla-tests-tma
        headers: credentials(user)
      assert_response :forbidden
    end
  end  

  test "GET /sla/caches.xml should forbidden the sla cache for tohers" do
    ['reporter','other'].each do |user|
      get "/sla/caches.xml?issue.status_id=*",
        headers: credentials(user)
      assert_response :forbidden
    end
  end

  test "GET /sla/caches.json should forbidden the sla cache for tohers" do
    ['reporter','other'].each { |user|
      get "/sla/caches.json?issue.status_id=*",
        headers: credentials(user)
      assert_response :forbidden
    }
  end  

  test "GET /sla/caches.xml should unauthorized the sla cache withtout credentials" do
      get "/sla/caches.xml?issue.status_id=*"
      assert_response :unauthorized
  end    

  test "GET /sla/caches.json should unauthorized the sla cache withtout credentials" do
    get "/sla/caches.json?issue.status_id=*"
    assert_response :unauthorized
  end


  # Sla#show in XML

  test "GET /sla/caches/:id.xml should return the sla cache tma/dev" do
    sla_cache = SlaCache.where(project: 1).order(:id).first # project-sla-tests-tma
    ['admin','manager','developer'].each do |user|
      get "/sla/caches/#{sla_cache.id}.xml",
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_show_xml(sla_cache)
    end    
    ['sysadmin'].each do |user|
      get "/sla/caches/#{sla_cache.id}.xml",
        headers: credentials(user)
      assert_response :forbidden
    end
    ['admin','manager','developer'].each do |user|
      get "/projects/project-sla-tests-tma/sla/caches/#{sla_cache.id}.xml",
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_show_xml(sla_cache)
    end
    ['sysadmin'].each do |user|
      get "/projects/project-sla-tests-tma/sla/caches/#{sla_cache.id}.xml",
        headers: credentials(user)
      assert_response :forbidden
    end
  end

  test "GET /sla/caches/:id.json should return the sla cache for developer" do
    sla_cache = SlaCache.where(project: 1).order(:id).first # project-sla-tests-tma
    ['admin','manager','developer'].each do |user|
      get "/sla/caches/#{sla_cache.id}.json",
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_show_json(sla_cache)
    end    
    ['sysadmin'].each do |user|
      get "/sla/caches/#{sla_cache.id}.json",
        headers: credentials(user)
      assert_response :forbidden
    end
    ['admin','manager','developer'].each do |user|
      get "/projects/project-sla-tests-tma/sla/caches/#{sla_cache.id}.json",
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_show_json(sla_cache)
    end
    ['sysadmin'].each do |user|
      get "/projects/project-sla-tests-tma/sla/caches/#{sla_cache.id}.json",
        headers: credentials(user)
      assert_response :forbidden
    end
  end

  test "GET /sla/caches/:id.xml should return the sla cache std/sys" do
    sla_cache = SlaCache.where(project: 2).order(:id).first # project-sla-tests-std
    ['admin','manager','sysadmin'].each do |user|
      get "/sla/caches/#{sla_cache.id}.xml",
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_show_xml(sla_cache)
    end    
    ['developer'].each do |user|
      get "/sla/caches/#{sla_cache.id}.xml",
        headers: credentials(user)
        assert_response :forbidden
    end
    ['admin','manager','sysadmin'].each do |user|
      get "/projects/project-sla-tests-std/sla/caches/#{sla_cache.id}.xml",
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_show_xml(sla_cache)
    end
    ['developer'].each do |user|
      get "/projects/project-sla-tests-std/sla/caches/#{sla_cache.id}.xml",
        headers: credentials(user)
      assert_response :forbidden
    end
  end

  test "GET /sla/caches/:id.json should return the sla cache std/sys" do
    sla_cache = SlaCache.where(project: 2).order(:id).first # project-sla-tests-std
    ['admin','manager','sysadmin'].each do |user|
      get "/sla/caches/#{sla_cache.id}.json",
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_show_json(sla_cache)
    end
    ['developer'].each do |user|
      get "/sla/caches/#{sla_cache.id}.json",
        headers: credentials(user)
      assert_response :forbidden
    end
    ['admin','manager','sysadmin'].each do |user|
      get "/projects/project-sla-tests-std/sla/caches/#{sla_cache.id}.json",
        headers: credentials(user)
      assert_response :success
      assert_sla_cache_show_json(sla_cache)
    end
    ['developer'].each do |user|
      get "/projects/project-sla-tests-std/sla/caches/#{sla_cache.id}.json",
        headers: credentials(user)
      assert_response :forbidden
    end
  end

  test "GET /sla/caches/:id.xml should forbidden the sla cache for others" do
    sla_cache = SlaCache.where(project: 1).order(:id).first # project-sla-tests-tma
    ['reporter','other'].each do |user|
      get "/projects/project-sla-tests-tma/sla/caches/#{sla_cache.id}.xml",
        headers: credentials(user)
      assert_response :forbidden      
      get "/sla/caches/#{sla_cache.id}.xml",
        headers: credentials(user)
      assert_response :forbidden
    end
    sla_cache = SlaCache.where(project: 2).order(:id).first # project-sla-tests-std
    ['reporter','other'].each do |user|
      get "/projects/project-sla-tests-std/sla/caches/#{sla_cache.id}.xml",
        headers: credentials(user)
      assert_response :forbidden     
      get "/sla/caches/#{sla_cache.id}.xml",
        headers: credentials(user)
      assert_response :forbidden
    end
  end

  test "GET /sla/caches/:id.json should forbidden the sla cache for others" do
    sla_cache = SlaCache.where(project: 1).order(:id).first # project-sla-tests-tma
    ['reporter','other'].each do |user|
      get "/projects/project-sla-tests-tma/sla/caches/#{sla_cache.id}.json",
        headers: credentials(user)
      assert_response :forbidden      
      get "/sla/caches/#{sla_cache.id}.json",
        headers: credentials(user)
      assert_response :forbidden
    end
    sla_cache = SlaCache.where(project: 2).order(:id).first # project-sla-tests-std
    ['reporter','other'].each do |user|
      get "/projects/project-sla-tests-std/sla/caches/#{sla_cache.id}.json",
        headers: credentials(user)
      assert_response :forbidden     
      get "/sla/caches/#{sla_cache.id}.json",
        headers: credentials(user)
      assert_response :forbidden
    end
  end  

  test "GET /sla/caches/:id.xml should unauthorized the sla cache withtout credentials" do
    sla_cache = SlaCache.where(project: 1).order(:id).first # project-sla-tests-tma
    get "/projects/project-sla-tests-tma/sla/caches/#{sla_cache.id}.xml"
    assert_response :unauthorized
    sla = SlaCache.first
    get "/sla/caches/#{sla_cache.id}.xml"
    assert_response :unauthorized    
    sla_cache = SlaCache.where(project: 2).order(:id).first # project-sla-tests-tma
    get "/projects/project-sla-tests-std/sla/caches/#{sla_cache.id}.xml"
    assert_response :unauthorized
    sla = SlaCache.first
    get "/sla/caches/#{sla_cache.id}.xml"
    assert_response :unauthorized      
  end

  test "GET /sla/caches/:id.json should unauthorized the sla cache withtout credentials" do
    sla_cache = SlaCache.where(project: 1).order(:id).first # project-sla-tests-tma
    get "/projects/project-sla-tests-tma/sla/caches/#{sla_cache.id}.json"
    assert_response :unauthorized
    sla = SlaCache.first
    get "/sla/caches/#{sla_cache.id}.json"
    assert_response :unauthorized    
    sla_cache = SlaCache.where(project: 2).order(:id).first # project-sla-tests-tma
    get "/projects/project-sla-tests-std/sla/caches/#{sla_cache.id}.json"
    assert_response :unauthorized
    sla = SlaCache.first
    get "/sla/caches/#{sla_cache.id}.json"
    assert_response :unauthorized      
  end

  # Sla#refresh in JSON

  test "GET /sla/caches/:id/refresh.json should return success on the sla cache for admin" do
    ['admin'].each do |user|
      sla_cache = SlaCache.find_by(project: 1) # project-sla-tests-tma
      get "/projects/project-sla-tests-tma/sla/caches/#{sla_cache.id}/refresh.json",
        headers: credentials(user)
      assert_response :success
      sla_cache = SlaCache.find_by(project: 2) # project-sla-tests-std
      get "/projects/project-sla-tests-std/sla/caches/#{sla_cache.id}/refresh.json",
        headers: credentials(user)
      assert_response :success            
      sla_cache = SlaCache.first
      get "/sla/caches/#{sla_cache.id}/refresh.json",
        headers: credentials(user)
      assert_response :success
    end
  end

  test "GET /sla/caches/:id/refresh.json should return success on the sla cache for manager" do
    ['manager'].each do |user|
      sla_cache = SlaCache.find_by(project: 1) # project-sla-tests-tma
      get "/projects/project-sla-tests-tma/sla/caches/#{sla_cache.id}/refresh.json",
        headers: credentials(user)
      assert_response :success
      sla_cache = SlaCache.find_by(project: 2) # project-sla-tests-std
      get "/projects/project-sla-tests-std/sla/caches/#{sla_cache.id}/refresh.json",
        headers: credentials(user)
      assert_response :success            
      sla_cache = SlaCache.first
      get "/sla/caches/#{sla_cache.id}/refresh.json",
        headers: credentials(user)
      assert_response :success
    end
  end

  test "GET /sla/caches/:id/refresh.json should return forbidden on sla cache for developer" do
    ['developer'].each do |user|
      sla_cache = SlaCache.find_by(project: 1) # project-sla-tests-tma
      get "/projects/project-sla-tests-tma/sla/caches/#{sla_cache.id}/refresh.json",
        headers: credentials(user)
      assert_response :success
      sla_cache = SlaCache.find_by(project: 2) # project-sla-tests-std
      get "/projects/project-sla-tests-std/sla/caches/#{sla_cache.id}/refresh.json",
        headers: credentials(user)
      assert_response :forbidden
      sla_cache = SlaCache.find_by(project: 1) # project-sla-tests-tma
      get "/sla/caches/#{sla_cache.id}/refresh.json",
        headers: credentials(user)
      assert_response :success
      sla_cache = SlaCache.find_by(project: 2) # project-sla-tests-std
      get "/sla/caches/#{sla_cache.id}/refresh.json",
        headers: credentials(user)
      assert_response :forbidden
    end
  end  

  test "GET /sla/caches/:id/refresh.json should return forbidden on sla cache for sysadmin" do
    ['sysadmin'].each do |user|
      sla_cache = SlaCache.find_by(project: 1) # project-sla-tests-tma
      get "/projects/project-sla-tests-std/sla/caches/#{sla_cache.id}/refresh.json",
        headers: credentials(user)
      assert_response :forbidden
      sla_cache = SlaCache.find_by(project: 2) # project-sla-tests-std
      get "/projects/project-sla-tests-std/sla/caches/#{sla_cache.id}/refresh.json",
        headers: credentials(user)
      assert_response :success
      sla_cache = SlaCache.find_by(project: 1) # project-sla-tests-tma
      get "/sla/caches/#{sla_cache.id}/refresh.json",
        headers: credentials(user)
      assert_response :forbidden
      sla_cache = SlaCache.find_by(project: 2) # project-sla-tests-std
      get "/sla/caches/#{sla_cache.id}/refresh.json",
        headers: credentials(user)
      assert_response :success
    end
  end

  test "GET /sla/caches/:id/refresh.json should forbidden the sla cache for others" do
    sla_cache = SlaCache.first
    ['reporter','other'].each do |user|
      get "/sla/caches/#{sla_cache.id}.json",
        headers: credentials(user)
      assert_response :forbidden
    end
  end
 
  test "GET /sla/caches/:id/refresh.json should unauthorized the sla cache withtout credentials" do
    sla_cache = SlaCache.first
    get "/sla/caches/#{sla_cache.id}.json"
    assert_response :unauthorized
  end  

  # Sla#create in XML

  test "PUT /sla/caches/:id.xml should missing the sla cache for others users" do
    sla_cache = SlaCache.find_by(project: 1) # project-sla-tests-tma
    ['admin','manager','developer','sysadmin','reporter','other'].each do |user|
      put "/sla/caches/#{sla_cache.id}.xml",
        params: {sla_cache: {}},
        headers: credentials(user)
      assert_response :missing
    end
    sla_cache = SlaCache.find_by(project: 2) # project-sla-tests-std
    ['admin','manager','developer','sysadmin','reporter','other'].each do |user|
      put "/sla/caches/#{sla_cache.id}.xml",
        params: {sla_cache: {}},
        headers: credentials(user)
      assert_response :missing
    end
  end
 
  test "PUT /sla/caches/:id.xml should missing the sla cache withtout credentials" do
    sla_cache = SlaCache.find_by(project: 1) # project-sla-tests-tma
    put "/sla/caches/#{sla_cache.id}.xml",
      params: {sla_cache: {}}
    assert_response :missing
    sla_cache = SlaCache.find_by(project: 2) # project-sla-tests-std
    put "/sla/caches/#{sla_cache.id}.xml",
      params: {sla_cache: {}}
    assert_response :missing
  end  

  # Sla#destroy in XML

  test "DELETE /sla/caches/:id.xml should success the sla cache for admin" do
    ['admin'].each do |user|
      sla_cache_id = SlaCache.find_by(project: 1).id # project-sla-tests-tma
      delete "/projects/project-sla-tests-tma/sla/caches/#{sla_cache_id}.xml",
        headers: credentials(user)
      assert_response :success
      renew_issue(sla_cache_id)
      delete "/sla/caches/#{sla_cache_id}.xml",
        headers: credentials(user)
      assert_response :success
      renew_issue(sla_cache_id)
      sla_cache_id = SlaCache.find_by(project: 2).id # project-sla-tests-std
      delete "/projects/project-sla-tests-std/sla/caches/#{sla_cache_id}.xml",
        headers: credentials(user)
      assert_response :success
      renew_issue(sla_cache_id)         
      delete "/sla/caches/#{sla_cache_id}.xml",
        headers: credentials(user)
      assert_response :success
      renew_issue(sla_cache_id)
    end
  end

  test "DELETE /sla/caches/:id.xml should success the sla cache for manager" do
    ['manager'].each do |user|
      sla_cache_id = SlaCache.find_by(project: 1).id # project-sla-tests-tma
      delete "/projects/project-sla-tests-tma/sla/caches/#{sla_cache_id}.xml",
        headers: credentials(user)
      assert_response :success
      renew_issue(sla_cache_id)      
      delete "/sla/caches/#{sla_cache_id}.xml",
        headers: credentials(user)
      assert_response :success
      renew_issue(sla_cache_id)
      sla_cache_id = SlaCache.find_by(project: 2).id # project-sla-tests-std
      delete "/projects/project-sla-tests-std/sla/caches/#{sla_cache_id}.xml",
        headers: credentials(user)
      assert_response :success
      renew_issue(sla_cache_id)      
      delete "/sla/caches/#{sla_cache_id}.xml",
        headers: credentials(user)
      assert_response :success
      renew_issue(sla_cache_id)
    end
  end

  test "DELETE /sla/caches/:id.xml should unauthorized the sla cache for others users" do
    ['reporter','other'].each do |user|
      sla_cache = SlaCache.find_by(project: 1) # project-sla-tests-tma
      delete "/sla/caches/#{sla_cache.id}.xml",
        headers: credentials(user)
      assert_response :forbidden
    end
    ['reporter','other'].each do |user|
      sla_cache = SlaCache.find_by(project: 2) # project-sla-tests-std
      delete "/sla/caches/#{sla_cache.id}.xml",
        headers: credentials(user)
      assert_response :forbidden
    end
  end  
 
  test "DELETE /sla/caches/:id.json should unauthorized the sla cache withtout credentials" do
    sla_cache = SlaCache.find_by(project: 1) # project-sla-tests-tma
    delete "/sla/caches/#{sla_cache.id}.xml"
    assert_response :unauthorized    
    sla_cache = SlaCache.find_by(project: 2) # project-sla-tests-std
    delete "/sla/caches/#{sla_cache.id}.xml"
    assert_response :unauthorized
  end    


  # TODO : Sla Caches Test +purge
  # TODO : Sla Caches Test +refresh

  private

  def assert_sla_cache_show_xml(sla_cache)
    assert_equal 'application/xml', @response.media_type
    assert_select 'sla_cache>id', integer: sla_cache.id
    assert_select 'sla_cache>issue_id', integer: sla_cache.issue_id
    # assert_select 'sla_cache>sla_level_id', integer: sla_cache.sla_level_id
  end

  def assert_sla_cache_index_xml(sla_cache,count)
    assert_equal 'application/xml', @response.media_type
    assert_select 'sla_caches' do
      assert_select '[total_count=?]', count
    end
    assert_select 'sla_caches>sla_cache:first-child' do
      assert_select '>id', integer: sla_cache.id
      assert_select '>issue_id', integer: sla_cache.issue_id
      assert_select '>sla_level_id', integer: sla_cache.sla_level_id
    end
  end

  def assert_sla_cache_show_json(sla_cache)
    assert_equal 'application/json', @response.media_type
    json = ActiveSupport::JSON.decode(response.body)
    assert_kind_of Hash, json
    assert_kind_of Hash, json['sla_cache']
    assert_equal sla_cache.id, json['sla_cache']['id']
    assert_equal sla_cache.issue_id, json['sla_cache']['issue_id']
    assert_equal sla_cache.sla_level_id, json['sla_cache']['sla_level']['id']
  end

  def assert_sla_cache_index_json(sla_cache,count)
    assert_equal 'application/json', @response.media_type
    json = ActiveSupport::JSON.decode(response.body)
    assert_kind_of Hash, json
    assert_kind_of Array, json['sla_caches']
    assert_kind_of Hash, json['sla_caches'].first
    assert json['sla_caches'].first.has_key?('id')
    assert json['sla_caches'].first.has_key?('issue_id')
    assert json['sla_caches'].first.has_key?('sla_level_id') 
    assert_equal(sla_cache.id, json['sla_caches'].first['id'])
    assert_equal(sla_cache.issue_id, json['sla_caches'].first['issue_id'])
    assert_equal(sla_cache.sla_level_id, json['sla_caches'].first['sla_level_id'])
    assert_equal(count, json['total_count'])
  end

end