# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

# File: redmine_sla/test/unit/sla_holiday_importer_test.rb
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

require_relative '../application_sla_units_test_case'

class SlaHolidayImporterTest < ApplicationSlaUnitsTestCase
  def holiday(date, name = 'Imported holiday')
    { 'date' => date, 'name' => name, 'national' => true, 'regions' => [] }
  end

  test 'preview identifies existing names without writes' do
    entry = SlaHoliday.first
    adapter = mock('holiday adapter')
    adapter.expects(:holidays).with(year: entry.date.year, country: 'FR', language: 'en').returns(
      [{ 'date' => entry.date.iso8601, 'name' => 'Different name' }]
    )
    before = SlaHoliday.count
    preview = SlaHolidayImporter.new(adapter: adapter).preview(year: entry.date.year, country: 'FR')
    assert_equal entry.name, preview.first['existing_name']
    assert_equal "Different name #{entry.date.year}", preview.first['name']
    assert_equal before, SlaHoliday.count
  end

  test 'repeated imports preserve existing records and combine same-day names' do
    importer = SlaHolidayImporter.new(adapter: nil)
    entries = [holiday('2098-01-01', 'One'), holiday('2098-01-01', 'Two')]
    assert_equal({ created: 1, skipped: 0 }, importer.import(holidays: entries))
    assert_equal 'One / Two', SlaHoliday.find_by(date: '2098-01-01').name
    assert_equal({ created: 0, skipped: 1 }, importer.import(holidays: [holiday('2098-01-01', 'Replacement')]))
    assert_equal 'One / Two', SlaHoliday.find_by(date: '2098-01-01').name
  end

  test 'failed creation rolls back the entire import' do
    importer = SlaHolidayImporter.new(adapter: nil)
    assert_no_difference 'SlaHoliday.count' do
      assert_raises ActiveRecord::RecordInvalid do
        importer.import(holidays: [holiday('2098-01-02'), holiday('2098-01-03', '')])
      end
    end
  end
end
