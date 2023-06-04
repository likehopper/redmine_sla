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

class SlaHoliday < ActiveRecord::Base

  unloadable

  include Redmine::SafeAttributes

  scope :visible, ->(*args) { where(SlaHoliday.visible_condition(args.shift || User.current, *args)) }

  # TODO : permit group by year functionnal
  # TODO : permit order by name/date functionnal
  default_scope { order(date: :desc) }

  validates_presence_of :name
  validates_presence_of :date

  validates_uniqueness_of :date

  safe_attributes *%w[name date]

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