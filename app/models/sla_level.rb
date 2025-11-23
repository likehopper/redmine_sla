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

class SlaLevel < ActiveRecord::Base

  
  belongs_to :sla
  belongs_to :sla_calendar
  belongs_to :custom_field, :class_name => 'IssueCustomField'

  has_many :sla_level_terms
  has_many :sla_caches
  has_many :sla_cache_spents, through: :sla_caches
  has_many :sla_project_trackers, through: :sla

  include Redmine::SafeAttributes

  accepts_nested_attributes_for :sla_level_terms, allow_destroy: true
  validate :sla_level_terms_greater_than_or_equal_to_zero

  scope :visible, ->(*args) { where(SlaLevel.visible_condition(args.shift || User.current, *args)) }

  default_scope { joins(:sla,:sla_calendar).left_joins(:custom_field) }
  
  validates_presence_of :name
  validates_presence_of :sla
  validates_presence_of :sla_calendar

  validates_associated :sla
  validates_associated :sla_calendar

  validates_uniqueness_of :name, :case_sensitive => false
  validates_uniqueness_of :sla, :scope => [ :sla_calendar ]

  safe_attributes *%w[name sla_id sla_calendar_id custom_field_id]

  before_save do
    # If the sla_priority_id reference changes, then terms of the old priorities must be deleted
    SlaLevelTerm.where(sla_level_id: self.id).destroy_all if attribute_changed?(:custom_field_id)
  end

  # No selection limitations
  def self.visible_condition(user, options = {})
    '1=1'
  end

  # For index and show
  def visible?(user=User.current)
    # TODO : permissions : user.allowed_to?(:view_sla, self.project, global: true) ???
    # TODO : permissions : only calendar of sla_project_trackers if ! project.nil?    
    user.allowed_to?(:view_sla, nil, global: true)
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
    name.to_s
  end 

  private

  def sla_level_terms_greater_than_or_equal_to_zero
    sla_level_terms.each do |child|
      if child.term.negative?
        errors.add(:base, l('sla_label.sla_level_term.negative'))
        return
      end
    end
  end

end