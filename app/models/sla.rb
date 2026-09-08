# frozen_string_literal: true

# File: redmine_sla/app/models/sla.rb
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

class Sla < ActiveRecord::Base

  has_many :sla_project_trackers
  has_many :sla_levels
  
  has_many :sla_level_terms, through: :sla_levels

  include Redmine::SafeAttributes

  scope :in_project, ->(project) {
    joins(:sla_project_trackers).
      where(sla_project_trackers: {project_id: project.id}).distinct
  }

  default_scope { }  

  validates_presence_of :name
  
  validates_uniqueness_of :name, :case_sensitive => false

  safe_attributes *%w[name]

  def self.visible(user=User.current)
    return all if user&.admin?
    return none unless user

    allowed_projects = Project.where(Project.allowed_to_condition(user, :view_sla)).select(:id)
    joins(:sla_project_trackers).
      where(sla_project_trackers: {project_id: allowed_projects}).distinct
  end

  # For index and show
  def visible?(user=User.current)
    user && (user.admin? || sla_project_trackers.any? { |link| user.allowed_to?(:view_sla, link.project) })
  end

  # For create and update
  def editable?(user=User.current)
    user.allowed_to?(:manage_sla, nil, global: true)
  end

  # For destroy
  def deletable?(user=User.current)
    user.allowed_to?(:manage_sla, nil, global: true)
  end

  # Print text for link objects
  def to_s
    self.name
  end

end
