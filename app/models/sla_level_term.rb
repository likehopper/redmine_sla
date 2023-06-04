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
  belongs_to :priority, :class_name => 'IssuePriority'

  include Redmine::SafeAttributes

  scope :visible, ->(*args) { where(SlaLevelTerm.visible_condition(args.shift || User.current, *args)) }

  default_scope {
#      select("sla_levels.*, sla_level_terms.*, sla_types.*, enumerations.*")
      joins(:sla_level,:sla_type,:priority)
      .order("sla_levels.name ASC, sla_types.name ASC, enumerations.position ASC") 
  }

  validates_presence_of :sla_level
  validates_presence_of :sla_type
  validates_presence_of :priority, :if => Proc.new {|sla_level_term| sla_level_term.new_record? || sla_level_term.priority_id_changed?}
  validates_presence_of :term

  validates_associated :sla_level
  validates_associated :sla_type

  validates_uniqueness_of :sla_level,
    :scope => [ :sla_type, :priority_id ],
    :message => l('sla_label.sla_level_term.exists')

  safe_attributes *%w[sla_level_id sla_type_id priority_id term]

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

  # Print text for link objects
  def to_s
    name.to_s
  end

  def self.find_by_level_type( param_sla_level_id, param_type_id, param_priority_id)
    # alternative to function sla_get_term
    find_by_level_type = self.where( sla_level_id: param_sla_level_id, sla_type_id: param_type_id, priority_id: [0,param_priority_id] ).order(priority_id: :desc).first
  end

end