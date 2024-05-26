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
  
  belongs_to :sla_level
  belongs_to :project
  belongs_to :issue
  
  has_many :sla_cache_spents

  validates_uniqueness_of :issue

  include Redmine::SafeAttributes
  safe_attributes *%w[]

  default_scope { joins(:sla_level,:issue,:project) }

  scope :visible, ->(*args) { where(SlaCache.visible_condition(args.shift || User.current, *args)) }

  # Selection limitations for users based on access issues
  def self.visible_condition(user=User.current, options = {})
    Issue.visible_condition(user, options = {})
  end

  # For index and refresh
  def visible?(user=User.current)
    user.allowed_to?(:view_sla, self.project) && self.issue.visible?
  end

  # For create and update
  def editable?(user=nil)
    false
  end

  # For destroy and purge
  def deletable?(user=User.current)
    user.allowed_to?(:manage_sla, self.project) && self.issue.visible?
  end

  def self.find_by_issue_id(issue_id)
    ActiveRecord::Base.connection.execute("SELECT sla_get_level(#{issue_id}) ; ")
    self.find_by(issue_id: issue_id)
  end

  # Class method for refresh cache
  def refresh
    # First, delete the entry in the sla_cache
    # SlaCache.where(issue: self.issue_id).destroy_all
    # Let's recalculate the sla_cache
    ActiveRecord::Base.connection.execute("SELECT sla_get_level(#{self.issue_id},true) ; ")
    # Then, let's recalculate the sla_cache_spents !
    SlaCacheSpent.refresh_by_issue_id(self.issue_id)
  end  

  def self.purge(project)
    if ( project.nil? )
      ActiveRecord::Base.connection.execute("TRUNCATE sla_caches CASCADE ; ")
    else
      SlaCache.where(project: project.id).destroy_all
    end
  end
    
  def self.destroy_by_issue_id(issue_id)
    SlaCache.where(issue: issue_id).destroy_all
  end              

  # For SlaCacheQuery#GroupBy
  if ActiveRecord::Base.connection.table_exists? 'sla_types'
    SlaType.all.each { |sla_type|
      define_method("get_sla_respect_#{sla_type.id}") do 
        self.issue.get_sla_respect(sla_type.id)
      end
      define_method("get_sla_remain_#{sla_type.id}") do 
        self.issue.get_sla_remain(sla_type.id)
      end
      define_method("get_sla_spent_#{sla_type.id}") do 
        self.issue.get_sla_spent(sla_type.id)
      end
      define_method("get_sla_term_#{sla_type.id}") do 
        self.issue.get_sla_term(sla_type.id)
      end
    }
  end
    
end