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

  include Redmine::SafeAttributes

  has_many :sla_schedules, inverse_of: :sla_calendar, :dependent => :destroy
  accepts_nested_attributes_for :sla_schedules, allow_destroy: true, reject_if: :all_blank
  #accepts_nested_attributes_for :sla_calendar_holidays, allow_destroy: true, reject_if: :all_blank

  scope :visible, ->(*args) { where(SlaCalendar.visible_condition(args.shift || User.current, *args)) }
  
  default_scope { order(name: :asc) }  

  validates_presence_of :name
  
  validates_uniqueness_of :name, :case_sensitive => false

  safe_attributes *%w[name]

  def self.visible_condition(user, options = {})
    Rails.logger.warn "======>>> models / sla_calendar->visible_condition() <<<====== "
    '1=1'
  end

  def editable_by?(user)
    Rails.logger.warn "======>>> models / sla_calendar->editable_by() <<<====== "
    editable?(user)
  end

  def visible?(user = nil)
    Rails.logger.warn "======>>> models / sla_calendar->visible() <<<====== "
    user ||= User.current
    user.allowed_to?(:manage_sla, nil, global: true)
  end

  def editable?(user = nil)
    Rails.logger.warn "======>>> models / sla_calendar->editable() <<<====== "
    user ||= User.current
    user.allowed_to?(:manage_sla, nil, global: true)
  end

  def deletable?(user = nil)
    Rails.logger.warn "======>>> models / sla_calendar->deletable() <<<====== "
    user ||= User.current
    user.allowed_to?(:manage_sla, nil, global: true)
  end

  def self.human_attribute_name(*args)
    Rails.logger.warn "======>>> SlaCalendar->human_attribute_name(#{args[0].to_s}) <<<====== "
    super
  end

  # Print text for link objects
  def to_s
    name.to_s
  end

end