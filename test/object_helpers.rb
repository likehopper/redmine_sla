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

module ObjectHelpers

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

  # Generates an unsaved SlaCalendar
  def SlaCalendar.generate(attributes={})
    sla_calendar = SlaCalendar.new()
    sla_calendar.name = attributes.key?(:name) ? attributes[:name] : "SlaCalendar #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}.#{(Time.now.usec/100.0).round.to_s.rjust(4,'0')}"
    yield sla_calendar if block_given?
    sla_calendar
  end

  # Generates a saved SlaCalendar
  def SlaCalendar.generate!(attributes={}, &block)
    sla_calendar = SlaCalendar.generate(attributes, &block)
    sla_calendar.save!
    sla_calendar.reload
  end

end
