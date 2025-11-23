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

  belongs_to :sla_cache
  belongs_to :sla_type
  belongs_to :project
  belongs_to :issue

  has_one :sla_level, through: :sla_cache

  include Redmine::SafeAttributes
  #safe_attributes *%w[sla_cache_id sla_type_id updated_on spent]
  safe_attributes *%w[]

  # Join order is important
  # default_scope { joins(:project,:issue,sla_cache: :sla_level) }
  default_scope { joins(:project,:issue,:sla_cache,:sla_type) }

  scope :visible, ->(*args) { where(SlaCacheSpent.visible_condition(args.shift || User.current, *args)) }

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
  
  def self.find_by_issue_and_type_id(issue,sla_type_id)
    ActiveRecord::Base.connection.execute("SELECT sla_get_spent(#{issue.id},#{sla_type_id}) ; ")
    self.find_by(issue_id: issue.id,sla_type_id: sla_type_id)
  end

  # Class method for refresh cache
  def self.refresh_by_issue_id(issue_id)
    SlaType.all.each do |sla_type|
      ActiveRecord::Base.connection.execute("SELECT sla_get_spent(#{issue_id},#{sla_type.id}) ; ")
    end
  end  

  # Class method for refresh cache
  def refresh
    ActiveRecord::Base.connection.execute("SELECT sla_get_spent(#{self.sla_cache.issue_id},#{self.sla_type.id}) ; ")
  end

  def self.purge()
    return ActiveRecord::Base.connection.select_value("TRUNCATE sla_cache_spents CASCADE ; ")
  end  
    
end