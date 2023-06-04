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

class SlaCache < ActiveRecord::Base

  unloadable
  
  belongs_to :issue
  belongs_to :sla_level

  acts_as_activity_provider :type => "sla",
                            :permission => :view_sla,
                            :scope => preload({:issue => :project})

  acts_as_searchable :columns => ["#{table_name}.subject"],
                     :scope => lambda { includes([:issue => :project]).order("#{table_name}.id") },
                     :project_key => "#{Issue.table_name}.project_id"             


  def self.find_by_issue(param_issue_id)
    return self.where(issue_id: param_issue_id).first
  end

  def self.find_or_new(param_issue_id)
    ActiveRecord::Base.connection.execute("SELECT sla_get_level(#{param_issue_id}) ; ")
    #tmp_s = ActiveRecord::Base.connection.select_value("SELECT sla_get_level(#{param_issue_id}) ; ")
    #tmp_a = tmp_s.split(",")
    #Rails.logger.warn "======>>> sla_cache_id = #{tmp_a[0]} sla_level_id = #{tmp_a[1]} <<<====== "
    sla_cache = self.find_by_issue(param_issue_id)
    sla_cache
  end
  
  # Class method for update cache
  def self.update(param_issue_id)
    ActiveRecord::Base.connection.execute("SELECT sla_get_level(#{param_issue_id}) ; ")
  end

  # Class method for update cache
  def self.update_cascade(param_issue_id)
    ActiveRecord::Base.connection.execute("SELECT sla_get_level(#{param_issue_id}) ; ")
    SlaCacheSpent.update_by_issue(param_issue_id)
    return SlaCache.where(issue_id: param_issue_id).first
  end    

  def self.destroy_by_issue_id(param_issue_id)
    return SlaCache.where(issue: param_issue_id).destroy_all
  end  
                  
  def self.purge()
    return ActiveRecord::Base.connection.execute("TRUNCATE sla_caches CASCADE ; ")
  end  

  # instance method for update cache
  def update()
    ActiveRecord::Base.connection.execute("SELECT sla_get_level(#{self.issue_id}) ; ")
  end
    
end