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

class SlaCalendarHoliday < ActiveRecord::Base

  unloadable

  belongs_to :sla_calendar
  belongs_to :sla_holiday

  include Redmine::SafeAttributes

  scope :visible, ->(*args) { where(SlaCalendarHoliday.visible_condition(args.shift || User.current, *args)) }

  default_scope {
    joins(:sla_calendar,:sla_holiday)
    #.order("sla_calendars.name ASC,sla_holidays.date DESC")
  }

  validates_presence_of :sla_calendar
  validates_presence_of :sla_holiday

  validates_associated :sla_calendar
  validates_associated :sla_holiday

  validates_uniqueness_of :sla_calendar,
    :scope => [ :sla_holiday ],
    :message => l('sla_label.sla_calendar_holiday.exists')
  
  validates :match, inclusion: [true, false]
  validates :match, exclusion: [nil]

  safe_attributes *%w[sla_calendar_id sla_holiday_id match]

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

  def self.human_attribute_name(*args)
    Rails.logger.warn "======>>> SlaCalendarHoliday->human_attribute_name(#{args[0].to_s}) <<<====== "
    super
  end

  def to_s
    name.to_s
  end

end