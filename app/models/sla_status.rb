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

class SlaStatus < ActiveRecord::Base

  unloadable if defined?(Rails) && !Rails.autoloaders.zeitwerk_enabled?
  
  belongs_to :sla_type
  belongs_to :status, :class_name => 'IssueStatus'

  include Redmine::SafeAttributes

  scope :visible, ->(*args) { where(SlaStatus.visible_condition(args.shift || User.current, *args)) }

  default_scope { joins(:sla_type,:status) }

  validates_presence_of :sla_type
  validates_presence_of :status

  validates_associated :sla_type
  validates_associated :status
  
  validates_uniqueness_of :sla_type_id, :scope => [ :status_id ]

  safe_attributes *%w[sla_type_id status_id]

  # No selection limitations
  def self.visible_condition(user, options = {})
    '1=1'
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

end