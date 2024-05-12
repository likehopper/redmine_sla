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

  # Generates an unsaved Sla
  def Sla.generate(attributes={})
    sla = Sla.new()
    sla.name = "Generated SLA #{rand}" if sla.name.blank?
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

  # Generates an unsaved SlaType
  def SlaStatus.generate(attributes={})
    sla_status = SlaStatus.new()
    sla_status.sla_type_id = SlaType.generate!.id
    sla_status.status_id = IssueStatus.first.id 
    yield sla_status if block_given?
    sla_status
  end

  # Generates a saved SlaType
  def SlaStatus.generate!(attributes={}, &block)
    sla_status = SlaStatus.generate(attributes, &block)
    sla_status.save!
    sla_status.reload
  end

  # Generates an unsaved SlaCalendar
  def SlaCalendar.generate(attributes={})
    sla_calendar = SlaCalendar.new()
    sla_calendar.name = "Generated SLA Calendar #{rand}" if sla_calendar.name.blank?
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
