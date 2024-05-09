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

class SlaLevelTerm < ActiveRecord::Base

  unloadable
  
  belongs_to :sla_level
  belongs_to :sla_type
  belongs_to :custom_field_enumeration
  belongs_to :priority, :class_name => 'IssuePriority'
  
  include Redmine::SafeAttributes

  scope :visible, ->(*args) { where(SlaLevelTerm.visible_condition(args.shift || User.current, *args)) }

  default_scope {
      # select("sla_levels.*, sla_level_terms.*, sla_types.*, enumerations.*")
      #select("( CASE WHEN enumerations.id IS NULL THEN ELSE enumerations))")
      #joins(:sla_level,:sla_type,:priority)
      joins(:sla_level,:sla_type)
      #.joins("LEFT JOIN enumerations ON ( ( CASE WHEN sla_level_terms.sla_priority_id~E'^\\\\d+$' THEN sla_level_terms.sla_priority_id::INTEGER ELSE 0 END ) = enumerations.id ) )")
      #.joins("LEFT JOIN custom_values ON sla_level_terms.custom_field_id = custom_values.custom_field_id")
      # .order("sla_levels.name ASC, sla_types.name ASC, enumerations.position ASC") 
  }

  validates_presence_of :sla_level
  validates_presence_of :sla_type
  # Todo : validate priority presence with SlaPriority ?
  #validates_presence_of :sla_priority_id, :if => Proc.new {|sla_level_term| sla_level_term.new_record? || sla_level_term.sla_priority_id_changed?}
  validates_presence_of :sla_priority_id
  validates_presence_of :term
  validates :term, numericality: { greater_than_or_equal_to: 0 }

  validates_associated :sla_level
  validates_associated :sla_type

  validates_uniqueness_of :sla_level,
    :scope => [ :sla_type, :sla_priority_id ],
    :message => l('sla_label.sla_level_term.exists')

  safe_attributes *%w[sla_level_id sla_type_id sla_priority_id term]

  before_save do
    # Synchronize sla_priority_id field with priority_id & custom_field_enumeration_id
    if self.sla_level.custom_field_id.nil?
      self.priority_id = self.sla_priority_id
      self.custom_field_enumeration_id = nil
    else
      self.priority_id = nil
      self.custom_field_enumeration_id = self.sla_priority_id
    end
  end 

  def self.visible_condition(user, options = {})
    '1=1'
  end

  def editable_by?(user)
    editable?(user)
  end

  def visible?(user = nil)
    user ||= User.current
    user.allowed_to?(:manage_sla, nil, global: true)
  end

  def editable?(user = nil)
    user ||= User.current
    user.allowed_to?(:manage_sla, nil, global: true)
  end

  def deletable?(user = nil)
    user ||= User.current
    user.allowed_to?(:manage_sla, nil, global: true)
  end

  # Find a contractual term through 3 parameters ( sla_level, sla_type and sla_priority_id ) for SlaLevel#show & SlaLevel#nested
  def self.find_by_level_type_priority( sla_level_id, sla_type_id, sla_priority_id )
    self.find_by( sla_level_id: sla_level_id, sla_type_id: sla_type_id, sla_priority_id: sla_priority_id ) if ! sla_priority_id.nil?
  end

  # Find a contractual term through 2 parameters ( sla_cache, sla_type  )
  def self.find_by_issue_and_type_id(issue,sla_type_id)
    result = issue.get_sla_level
    return result if result.nil?
    sla_level_id, custom_field_id = result.values_at(:id, :custom_field_id) 
    sla_priority_id = SlaPriority.create_by_issue(issue)
    self.find_by( sla_level_id: sla_level_id, sla_type_id: sla_type_id, sla_priority_id: sla_priority_id.id.to_s ) if ! sla_priority_id.nil?
  end

end