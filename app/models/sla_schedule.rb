# frozen_string_literal: true

# File: redmine_sla/app/models/sla_schedule.rb
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
  include Redmine::I18n
  include Redmine::SafeAttributes
  include RedmineSla::InvalidatesSlaCache

  scope :visible, ->(*args) { where(SlaSchedule.visible_condition(args.shift || User.current, *args)) }

  # No explicit select() here: Rails already selects "sla_schedules.*" by
  # default for a plain joins(). An explicit select("sla_schedules.*") makes
  # ActiveRecord#count reuse it as the COUNT() argument (COUNT(sla_schedules.*)),
  # which PostgreSQL accepts (row-wildcard extension) but MySQL rejects with a
  # syntax error -- breaking every paginated/API index action on this model.
  default_scope { joins(:sla_calendar) }

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
    :scope => [ :dow, :end_time ],
    :message => l('sla_label.sla_schedule.exists')

  validate :sla_schedules_inconsistency
  validate :sla_schedules_overlapless

  safe_attributes *%w[sla_calendar_id dow start_time end_time match]

  # Normalize times to full HH:MM:SS only when the value is already a proper
  # Time/Date object (i.e. successfully cast by ActiveRecord).
  # Guards against nil, strings, or failed casts that would raise NoMethodError.
  before_save do
    self.start_time = self.start_time.strftime("%H:%M:00") if self.start_time.is_a?(Time)
    self.end_time   = self.end_time.strftime("%H:%M:59")   if self.end_time.is_a?(Time)
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

  def sla_cache_level_ids_for_invalidation
    calendar_ids = [sla_calendar_id, attribute_in_database("sla_calendar_id")].compact.uniq
    SlaLevel.unscoped.where(sla_calendar_id: calendar_ids).pluck(:id)
  end
  
  # Validate that start_time < end_time, only when both are valid Time objects.
  # Uses local variables (not ivars) to avoid polluting instance state.
  def sla_schedules_inconsistency
    start_str = start_time.strftime("%H:%M") if start_time.is_a?(Time)
    end_str   = end_time.strftime("%H:%M")   if end_time.is_a?(Time)

    # Skip comparison if either value is missing — presence validations
    # will already report the blank field error.
    return unless start_str.present? && end_str.present?

    # Start must be strictly before end.
    errors.add(:base, l('sla_label.sla_schedule.inconsistency')) unless start_str < end_str
  end

  # Reject overlaps regardless of whether a schedule is saved directly or
  # through SlaCalendar's nested form. The calendar association contains both
  # persisted schedules and unsaved nested siblings during validation.
  def sla_schedules_overlapless
    return unless sla_calendar && dow.present?
    return unless start_time.is_a?(Time) && end_time.is_a?(Time)

    overlapping = sla_calendar.sla_schedules.any? do |other|
      next false if other.equal?(self) || (persisted? && other.id == id) || other.marked_for_destruction?
      next false unless other.dow == dow
      next false unless other.start_time.is_a?(Time) && other.end_time.is_a?(Time)

      other.start_time <= end_time && start_time <= other.end_time
    end

    errors.add(:base, l('sla_label.sla_schedule.overlaps')) if overlapping
  end
    
end
