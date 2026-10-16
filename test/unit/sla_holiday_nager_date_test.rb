# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

# File: redmine_sla/test/unit/sla_holiday_nager_date_test.rb
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

class SlaHolidayNagerDateTest < ApplicationSlaUnitsTestCase
  def setup
    super
    @adapter = SlaHolidayAdapters::NagerDate.new
    @http = mock('HTTP')
    Net::HTTP.stubs(:new).returns(@http)
    @http.stubs(:use_ssl=)
    @http.stubs(:open_timeout=)
    @http.stubs(:read_timeout=)
  end

  def response(data)
    result = Net::HTTPOK.new('1.1', '200', 'OK')
    result.stubs(:body).returns(data.to_json)
    result
  end

  def holiday(attributes = {})
    { 'date' => '2026-01-01', 'localName' => 'Jour de l’an', 'name' => 'New Year',
      'countryCode' => 'FR', 'global' => true, 'counties' => nil, 'types' => ['Public'] }.merge(attributes)
  end

  test 'country endpoint checks access and returns country options' do
    @http.expects(:get).with('/api/v3/AvailableCountries', 'Accept' => 'application/json').returns(response([{ 'countryCode' => 'FR', 'name' => 'France' }]))
    assert @adapter.accessible?
  end

  test 'normalizes local names and regional public holidays' do
    @http.expects(:get).returns(response([holiday, holiday('global' => false, 'counties' => ['FR-67']), holiday('types' => ['Bank'])]))
    result = @adapter.holidays(year: 2026, country: 'fr')
    assert_equal 2, result.size
    assert_equal 'Jour de l’an', result.first['name']
    assert_equal ['FR-67'], result.last['regions']
    assert_equal false, result.last['national']
  end

  test 'rejects holidays outside requested year' do
    @http.expects(:get).returns(response([holiday('date' => '2025-01-01')]))
    assert_equal 'invalid_response', assert_raises(SlaHolidayAdapters::NagerDate::Error) { @adapter.holidays(year: 2026, country: 'FR') }.message
  end

  test 'rejects invalid input before accessing network' do
    @http.expects(:get).never
    assert_raises(SlaHolidayAdapters::NagerDate::Error) { @adapter.holidays(year: '../2026', country: 'FR') }
  end

  test 'handles timeout and DNS failure' do
    [Net::ReadTimeout.new, SocketError.new].each do |error|
      @http.expects(:get).raises(error)
      assert_equal 'unavailable', assert_raises(SlaHolidayAdapters::NagerDate::Error) { @adapter.available_countries }.message
    end
  end

  test 'handles HTTP errors and malformed JSON' do
    @http.expects(:get).returns(Net::HTTPServiceUnavailable.new('1.1', '503', 'Unavailable'))
    assert_raises(SlaHolidayAdapters::NagerDate::Error) { @adapter.available_countries }
    result = Net::HTTPOK.new('1.1', '200', 'OK')
    result.stubs(:body).returns('<html>Error</html>')
    @http.expects(:get).returns(result)
    assert_equal 'invalid_response', assert_raises(SlaHolidayAdapters::NagerDate::Error) { @adapter.available_countries }.message
  end
end
