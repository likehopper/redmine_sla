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

  belongs_to :sla_calendar

  extend Redmine::I18n
  include Redmine::SafeAttributes

  scope :visible, ->(*args) { where(SlaSchedule.visible_condition(args.shift || User.current, *args)) }

  default_scope { select("sla_schedules.*").joins(:sla_calendar) }

  # It is important not to convert times based on time zone !
  # ( cf. https://api.rubyonrails.org/classes/ActiveRecord/Timestamp.html )
  self.skip_time_zone_conversion_for_attributes = [:start_time,:end_time]

  validates_presence_of :sla_calendar
  validates_presence_of :dow
  validates_presence_of :start_time
  validates_presence_of :end_time

  #validates_associated :sla_calendar

  validates :match, inclusion: [true, false]
  validates :match, exclusion: [nil]
  
  validates_uniqueness_of :sla_calendar_id,
    :scope => [ :dow, :start_time ],
    :message => l('sla_label.sla_schedule.exists')

  validates_uniqueness_of :sla_calendar_id,
    :scope => [ :dow, :start_time, :end_time ],
    :message => l('sla_label.sla_schedule.exists')

  validate :sla_schedules_inconsistency

  safe_attributes *%w[sla_calendar_id dow start_time end_time match]

  before_save do
    self.start_time = self.start_time.strftime("%H:%M:00") if self.start_time.present?
    self.end_time = self.end_time.strftime("%H:%M:59") if self.end_time.present?
  end  

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

  private
  
  def sla_schedules_inconsistency
    # Format datas
    @start_time = self.start_time.strftime("%H:%M") if self.start_time.present?
    @end_time = self.end_time.strftime("%H:%M") if self.end_time.present?
    # Logs 
    # "==>> sla_schedules_inconsistency ID=#{self.id}, #{self.sla_calendar_id}, #{self.dow}, #{@start_time} #{@end_time}"
    #Rails.logger.debug "==>> sla_schedules_inconsistency #{@start_time} < #{@end_time}) = #{@start_time < @end_time}"
    #Rails.logger.debug "==>> sla_schedules_inconsistency ok? #{self.marked_for_destruction?}"
    # Start must be strictly before end!
    if not ( @start_time.present? && @end_time.present? && ( @start_time < @end_time ) ) 
      #Rails.logger.debug "==>> sla_schedules_inconsistency END ERROR"
      errors.add(:base,l('sla_label.sla_schedule.inconsistency'))
    end
  end
    
end
