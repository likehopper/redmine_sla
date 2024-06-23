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

class SlaCalendar < ActiveRecord::Base

  unloadable

  has_many :sla_levels
  has_many :sla_schedules, inverse_of: :sla_calendar, :dependent => :destroy

  include Redmine::SafeAttributes

  accepts_nested_attributes_for :sla_schedules, allow_destroy: true, :reject_if => proc { |attributes| attributes.any? {|k,v| v.blank?} } # :any_blank

  scope :visible, ->(*args) { where(SlaCalendar.visible_condition(args.shift || User.current, *args)) }
  
  default_scope { } 

  validates_presence_of :name
  
  validates_uniqueness_of :name, :case_sensitive => false

  safe_attributes *%w[name]

  # No selection limitations
  def self.visible_condition(user, options = {})
    '1=1'
  end

  # For index and show
  def visible?(user=User.current)
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

end