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

class SlaSchedule < ActiveRecord::Base

  unloadable
  belongs_to :sla_calendar

  include Redmine::SafeAttributes

  scope :visible, ->(*args) { where(SlaSchedule.visible_condition(args.shift || User.current, *args)) }

  #default_scope { joins(:sla_calendar).order(dow: :asc, start_time: :asc) }  
  default_scope { joins(:sla_calendar).order("sla_schedules.dow ASC, sla_schedules.start_time ASC") }  
  
  validates_presence_of :sla_calendar
  validates_presence_of :dow
  validates_presence_of :start_time
  validates_presence_of :end_time

  validates_associated :sla_calendar

  validates :match, inclusion: [true, false]
  validates :match, exclusion: [nil]
  
  validates_uniqueness_of :sla_calendar_id,
    :scope => [ :dow, :start_time, :end_time, :match ],
    :message => l('sla_label.sla_schedule.exists')

  # TODO: other constraint like start time before end time
  # TODO: other constraint like time slot not in another time slot 

  safe_attributes *%w[sla_calendar_id dow start_time end_time match]

  before_save do
    self.start_time = self.start_time.strftime("%H:%M:00")
    self.end_time = self.end_time.strftime("%H:%M:59")
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
  
  def to_s
    name.to_s
  end  
    
end