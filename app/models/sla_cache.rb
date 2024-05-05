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
  belongs_to :issue
  belongs_to :project

  has_many :sla_cache_spents
 
  include Redmine::SafeAttributes
  safe_attributes *%w[]

  default_scope {
    joins(:sla_level,:issue,:project)
  #  .order(start_date: :desc) 
  }

  scope :visible, lambda {|*args|
    user = args.shift || User.current
    joins(:sla_level,:issue,:project).
      where(Issue.visible_condition(user, *args))
  }

  validates_uniqueness_of :issue

  def self.visible_condition(user, options = {})
    '1=1'
  end

  def visible?(user = nil)
    user ||= User.current
    user.allowed_to?(:manage_sla, nil, global: true)
  end

  def self.find_by_issue_id(issue_id)
    ActiveRecord::Base.connection.execute("SELECT sla_get_level(#{issue_id}) ; ")
    self.find_by(issue_id: issue_id)
  end

  # Class method for refresh cache
  def refresh
    # First, delete the entry in the sla_cache
    SlaCache.where(issue: self.issue_id).destroy_all
    # Let's recalculate the sla_cache
    ActiveRecord::Base.connection.execute("SELECT sla_get_level(#{self.issue_id}) ; ")
    # Then, let's recalculate the sla_cache_spents !
    SlaCacheSpent.update_by_issue_id(self.issue_id)
  end  

  def self.purge
    return ActiveRecord::Base.connection.execute("TRUNCATE sla_caches CASCADE ; ")
  end
    
  def self.destroy_by_issue_id(issue_id)
    return SlaCache.where(issue: issue_id).destroy_all
  end              

  def editable?(user = nil)
    false
  end

  def deletable?(user = nil)
    user ||= User.current
    user.allowed_to?(:manage_sla, nil, global: true)
  end

  #def to_s()
  #  issue.to_s.length > 47 ? "#{issue.to_s.first(47)}..." : issue.to_s
  #end
    
end