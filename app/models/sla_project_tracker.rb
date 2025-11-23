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

  belongs_to :project
  belongs_to :tracker
  belongs_to :sla

  has_many :sla_levels, through: :sla
  has_many :sla_level_terms, through: :sla_levels
  has_many :sla_types, through: :sla_level_terms

  after_save :sla_cache_update
  after_destroy :sla_cache_destroy

  extend Redmine::I18n
  include Redmine::SafeAttributes

  default_scope { joins(:tracker) }  

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

  # scope :visible, lambda {|*args|
  #   user = args.shift || User.current
  #   base = Project.allowed_to_condition(user, :manage_sla, *args)
  #   eager_load(:project)
  # }

  default_scope { joins(:sla,:tracker,:project) }

  # define a scope to search by project
  scope :in_project, ->(project_id) { where(project_id: project_id) }
  # scope :for_tracker_id, lambda { |tracker_id| where(:tracker_id => tracker_id) }  
  # scope :for_sla_id, lambda { |sla_id| where(:sla_id => sla_id) }  

  scope :visible, ->(*args) { where(SlaProjectTracker.visible_condition(args.shift || User.current, *args)) }

  # Selection limitations for users based on access issues
  def self.visible_condition(user=User.current, options = {})
    Project.allowed_to_condition(user,:manage_sla,options)
  end

  # For index and refresh
  def visible?(user=User.current)
    !user.nil? && user.allowed_to?(:manage_sla, project)
  end

  # For index and show
  def visible?(user=User.current)
    user.allowed_to?(:manage_sla, nil, global: true)
  end

  # For create and update
  def editable?(user=User.current)
    user.allowed_to?(:manage_sla, nil, global: true)
  end

  # For destroy
  def deletable?(user=User.current)
    user.allowed_to?(:manage_sla, nil, global: true)
  end

private

  def sla_cache_update
    # At any change, we update sla_cache affected by the old values
    SlaCache.where(project_id: self.project_id_before_last_save, tracker_id: self.tracker_id_before_last_save).find_each do |sla_cache|
      sla_cache.refresh
    end
  end

  def sla_cache_destroy
    # if sla_project_tracker destroyed then must destroy sla_cache
    SlaCache.where(project_id: self.project_id, tracker_id: self.tracker_id).destroy_all
  end

end
