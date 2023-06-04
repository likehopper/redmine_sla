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

class SlaProjectTracker < ActiveRecord::Base
  
  unloadable

  belongs_to :project
  belongs_to :tracker
  belongs_to :sla

  include Redmine::SafeAttributes

  default_scope { joins(:tracker).order("trackers.name ASC") }  

  validates_presence_of :project
  validates_presence_of :tracker
  validates_presence_of :sla

  validates_associated :project
  validates_associated :tracker
  validates_associated :sla
  
  validates_uniqueness_of :tracker,
    :scope => [ :project ],
    :message => l('sla_label.sla_project_tracker.exists')

  safe_attributes *%w[project_id tracker_id sla_id]

  scope :visible, lambda {|*args|
    user = args.shift || User.current
    base = Project.allowed_to_condition(user, :view_sla, *args)
    eager_load(:project)
  }

  # define a scope to search by project
  scope :in_project, ->(project_id) { where(project_id: project_id) }
  scope :for_tracker_id, lambda { |tracker_id| where(:tracker_id => tracker_id) }  
  scope :for_sla_id, lambda { |sla_id| where(:sla_id => sla_id) }  

end