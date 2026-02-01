# frozen_string_literal: true

# File: redmine_sla/test/helpers/sla_object_helpers.rb
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

module SlaObjectHelperTest

  # Generates an unsaved Tracker
  def Tracker.generate(attributes={})
    tracker = Tracker.new()
    tracker.name = attributes.key?(:name) ? attributes[:name] : "Tracker #{Time.now.strftime("%Y%m%d %H:%M:%S")}.#{(Time.now.usec/100.0).round.to_s.rjust(4,'0')}"
    tracker.default_status_id = IssueStatus.find_by(name: 'New').id
    yield tracker if block_given?
    tracker
  end

  # Generates a saved Tracker
  def Tracker.generate!(attributes={}, &block)
    tracker = Tracker.generate(attributes, &block)
    tracker.save!
    tracker.reload
  end

  # Generates an unsaved Sla
  def Sla.generate(attributes={})
    sla = Sla.new()
    sla.name = attributes.key?(:name) ? attributes[:name] : "Sla #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}.#{(Time.now.usec/100.0).round.to_s.rjust(4,'0')}"
    yield sla if block_given?
    sla
  end

  # Generates a saved Sla
  def Sla.generate!(attributes={}, &block)
    sla = Sla.generate(attributes, &block)
    sla.save!
    sla.reload
  end

  # Generates an unsaved SlaType
  def SlaType.generate(attributes={})
    sla_type = SlaType.new()
    sla_type.name = "Generated SLA Type #{rand}" if sla_type.name.blank?
    yield sla_type if block_given?
    sla_type
  end

  # Generates a saved SlaType
  def SlaType.generate!(attributes={}, &block)
    sla_type = SlaType.generate(attributes, &block)
    sla_type.save!
    sla_type.reload
  end

  # Generates an unsaved SlaStatus
  def SlaStatus.generate(attributes={})
    sla_status = SlaStatus.new()
    sla_status.sla_type_id = SlaType.generate!.id
    sla_status.status_id = IssueStatus.first.id 
    yield sla_status if block_given?
    sla_status
  end

  # Generates a saved SlaStatus
  def SlaStatus.generate!(attributes={}, &block)
    sla_status = SlaStatus.generate(attributes, &block)
    sla_status.save!
    sla_status.reload
  end

  # Generates an unsaved SlaHoliday
  def SlaHoliday.generate(attributes={})
    sla_holiday = SlaHoliday.new()
    sla_holiday.date = attributes.key?(:date) ? attributes[:date] : Date.today+rand(1..9999)
    sla_holiday.name = attributes.key?(:name) ? attributes[:name] : "SlaHoliday #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}.#{(Time.now.usec/100.0).round.to_s.rjust(4,'0')}"
    yield sla_holiday if block_given?
    sla_holiday
  end

  # Generates a saved SlaHoliday
  def SlaHoliday.generate!(attributes={}, &block)
    sla_holiday = SlaHoliday.generate(attributes, &block)
    sla_holiday.save!
    sla_holiday.reload
  end

  # Generates an unsaved SlaCalendar
  def SlaCalendar.generate(attributes={})
    sla_calendar = SlaCalendar.new()
    sla_calendar.name = attributes.key?(:name) ? attributes[:name] : "SlaCalendar #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}.#{(Time.now.usec/100.0).round.to_s.rjust(4,'0')}"
    yield sla_calendar if block_given?
    sla_calendar
  end

  # Generates a saved SlaCalendar
  def SlaCalendar.generate!(attributes={}, &block)
    sla_schedule = SlaCalendar.generate(attributes, &block)
    sla_schedule.save!
    sla_schedule.reload
  end

# Generates an unsaved SlaSchedule
def SlaSchedule.generate(attributes={})
  sla_schedule = SlaSchedule.new()
  sla_schedule.sla_calendar_id = attributes.key?(:sla_calendar) ? attributes[:sla_calendar] : SlaCalendar.generate!.id
  sla_schedule.dow = attributes.key?(:dow) ? attributes[:dow] : 1
  sla_schedule.start_time = attributes.key?(:start_time) ? attributes[:start_time] : format('%02d:%02d:00', rand(0..11), rand(0..59))
  sla_schedule.end_time = attributes.key?(:end_time) ? attributes[:end_time] : format('%02d:%02d:00', rand(12..23), rand(0..59))
  sla_schedule.match = attributes.key?(:match) ? attributes[:match] : false
  yield sla_schedule if block_given?
  sla_schedule
end

# Generates a saved SlaSchedule
def SlaSchedule.generate!(attributes={}, &block)
  sla_calendar = SlaSchedule.generate(attributes, &block)
  sla_calendar.save!
  sla_calendar.reload
end  

  # Generates an unsaved SlaLevel
  def SlaLevel.generate(attributes={})
    sla_level = SlaLevel.new()
    sla_level.name = attributes.key?(:name) ? attributes[:name] : "SlaLevel #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}.#{(Time.now.usec/100.0).round.to_s.rjust(4,'0')}"
    sla_level.sla_id = attributes.key?(:sla_id) ? attributes[:sla_id] : Sla.generate!.id
    sla_level.sla_calendar_id = attributes.key?(:sla_calendar_id) ? attributes[:sla_calendar_id] : SlaCalendar.generate!.id
    sla_level.custom_field_id = attributes.key?(:custom_field_id) ? attributes[:custom_field_id] : nil
    yield sla_level if block_given?
    sla_level
  end

  # Generates a saved SlaLevel
  def SlaLevel.generate!(attributes={}, &block)
    sla_level = SlaLevel.generate(attributes, &block)
    sla_level.save!
    sla_level.reload
  end

  # Generates an unsaved SlaLevelTerm
  def SlaLevelTerm.generate(attributes={})
    sla_level_term = SlaLevelTerm.new()
    sla_level_term.sla_level_id = attributes.key?(:sla_level_id) ? attributes[:sla_level_id] : SlaLevel.generate!.id
    sla_level_term.sla_type_id = attributes.key?(:sla_type_id) ? attributes[:sla_type_id] : SlaType.generate!.id
    sla_level_term.sla_priority_id = attributes.key?(:sla_priority_id) ? attributes[:sla_priority_id] : 2
    sla_level_term.term = attributes.key?(:term) ? attributes[:term] : 90
    yield sla_level_term if block_given?
    sla_level_term
  end

  # Generates a saved SlaLevelTerm
  def SlaLevelTerm.generate!(attributes={}, &block)
    sla_level_term = SlaLevelTerm.generate(attributes, &block)
    sla_level_term.save!
    sla_level_term.reload
  end    

  # Generates an unsaved SlaProjectTracker
  def SlaProjectTracker.generate(attributes={})
    sla_project_tracker = SlaProjectTracker.new()
    sla_project_tracker.project_id = attributes.key?(:project_id) ? attributes[:project_id].to_i : 1
    sla_project_tracker.tracker_id = attributes.key?(:tracker_id) ? attributes[:tracker_id].to_i : Tracker.generate!.id
    sla_project_tracker.sla_id = attributes.key?(:sla_id) ? attributes[:sla_id].to_i : Sla.generate!.id
    yield sla_project_tracker if block_given?
    sla_project_tracker
  end

  # Generates a saved SlaProjectTracker
  def SlaProjectTracker.generate!(attributes={}, &block)
    sla_project_tracker = SlaProjectTracker.generate(attributes, &block)
    sla_project_tracker.save!
    sla_project_tracker.reload
  end  

end
