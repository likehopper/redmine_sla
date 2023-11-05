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

class Sla < ActiveRecord::Base
  
  unloadable

  has_many :sla_project_trackers
  has_many :sla_levels
  
  has_many :sla_level_terms, through: :sla_levels

  include Redmine::SafeAttributes

  scope :visible, ->(*args) { where(Sla.visible_condition(args.shift || User.current, *args)) }

  default_scope { order(name: :asc) }

  validates_presence_of :name
  
  validates_uniqueness_of :name, :case_sensitive => false

  safe_attributes *%w[name]

  # Use for select in app/views/sla_settings_plugin/_sla_settings_plugin_logs.html.erb
  enum sla_log_levels: { 'sla_log_level_none': 0, 'sla_log_level_error': 1, 'sla_log_level_info': 2, 'sla_log_level_debug': 3 }

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

  def to_s
    name.to_s
  end

end