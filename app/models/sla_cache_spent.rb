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

class SlaCacheSpent < ActiveRecord::Base

  unloadable
  
  belongs_to :sla_cache
  belongs_to :sla_type
  
  self.primary_keys = :sla_cache_id, :sla_type_id

  def self.find_by_cache_type( param_sla_cache_id, param_type_id )
    return self.where( sla_cache_id: param_sla_cache_id, sla_type_id: param_type_id ).first
  end

  def self.find_or_new( param_sla_cache_id, param_type_id)
    sla_cache = SlaCache.find( param_sla_cache_id )
    ActiveRecord::Base.connection.execute("SELECT sla_get_spent(#{sla_cache.issue_id},#{param_type_id}) ; ")
    sla_cache_spent = self.find_by_cache_type( param_sla_cache_id, param_type_id )
    sla_cache_spent
  end

  # Class method for update cache
  def self.update_by_issue(param_issue_id)
    SlaType.all.each { |sla_type|
      ActiveRecord::Base.connection.execute("SELECT sla_get_spent(#{param_issue_id},#{sla_type.id}) ; ")
    }
  end

  def self.update_by_issue_type(param_issue_id,param_type_id)
      return ActiveRecord::Base.connection.select_values("SELECT * FROM sla_get_spent(#{param_issue_id},#{param_type_id}) AS slp(sla_cache_id bigint, sla_level_id integer, updated_on TIMESTAMP WITHOUT TIME ZONE, spent bigint, term integer ) ; ")
  end    

  # Instance method for update cache
  #def update()
  #  ActiveRecord::Base.connection.execute("SELECT sla_get_term(#{self.issue_id},#{self.sla_type.id}) ; ")
  #end 

  # TODO: prohibit access to properties and force the use of this method !
  def getIssueSpent(issue_id,type_id)
    # TODO: use the internal properties of the object!
    return ActiveRecord::Base.connection.select_value("SELECT sla_get_spent(#{issue_id.to_s},#{type_id.to_s}) ; ")
  end  

  def purge()
    return ActiveRecord::Base.connection.select_value("TRUNCATE sla_cache_spents CASCADE ; ")
  end    
    
end