# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

# File: redmine_sla/app/services/sla_holiday_importer.rb
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

# Import normalized holidays without overwriting existing dates or calendar links.
class SlaHolidayImporter
  def initialize(adapter:)
    @adapter = adapter
  end

  def preview(year:, country:, language: 'en')
    holidays = @adapter.holidays(year: year, country: country, language: language)
    existing = SlaHoliday.where(date: holidays.map { |holiday| holiday.fetch('date') }).pluck(:date, :name).to_h
    holidays.map do |holiday|
      date = Date.iso8601(holiday.fetch('date'))
      holiday.merge('name' => "#{holiday.fetch('name')} #{date.year}", 'existing_name' => existing[date])
    end
  end

  def import(holidays:)
    created = 0
    skipped = 0
    SlaHoliday.transaction do
      holidays.group_by { |holiday| holiday.fetch('date') }.each do |date, entries|
        if SlaHoliday.exists?(date: date)
          skipped += 1
          next
        end
        SlaHoliday.create!(date: date, name: entries.map { |holiday| holiday.fetch('name') }.uniq.join(' / '))
        created += 1
      end
    end
    { created: created, skipped: skipped }
  end
end
