# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

# File: redmine_sla/app/services/sla_holiday_adapters/nager_date.rb
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

require 'net/http'
require 'json'
require 'date'

module SlaHolidayAdapters
  # Convert Nager.Date responses to provider-independent holiday attributes.
  class NagerDate
    class Error < StandardError; end
    BASE_URL = 'https://nagerholidays.com/api/v4'

    def available_countries
      rows = request('/Countries/Available')
      raise Error, 'invalid_response' unless rows.is_a?(Array) && rows.any?
      rows.map do |row|
        unless row.is_a?(Hash) && row['countryCode'].is_a?(String) &&
               row['countryCode'].match?(/\A[A-Z]{2}\z/) && row['name'].is_a?(String) && !row['name'].strip.empty?
          raise Error, 'invalid_response'
        end
        [row['name'], row['countryCode']]
      end.sort
    end

    def holidays(year:, country:)
      year = year.to_s
      country = country.to_s.upcase
      raise Error, 'invalid_selection' unless year.match?(/\A\d{1,4}\z/) && year.to_i.between?(1, 9999) && country.match?(/\A[A-Z]{2}\z/)
      rows = request("/Holidays/#{country}/#{year.to_i}")
      raise Error, 'invalid_response' unless rows.is_a?(Array)
      rows.filter_map do |row|
        raise Error, 'invalid_response' unless row.is_a?(Hash)
        date = Date.iso8601(row.fetch('date'))
        name = row.fetch('name')
        regions = row['subdivisionCodes']
        types = row['holidayTypes']
        unless row['date'] == date.iso8601 && date.year == year.to_i && row['countryCode'] == country &&
               name.is_a?(String) && !name.strip.empty? && [true, false].include?(row['nationalHoliday']) &&
               types.is_a?(Array) && types.all? { |type| type.is_a?(String) && !type.empty? } &&
               (regions.nil? || (regions.is_a?(Array) && regions.all? do |region|
                 region.is_a?(String) && region.match?(/\A#{country}-[A-Z0-9]{1,3}\z/)
               end))
          raise Error, 'invalid_response'
        end
        next unless types.include?('Public')

        { 'date' => date.iso8601, 'name' => name.strip, 'national' => row['nationalHoliday'],
          'regions' => regions || [] }
      end.sort_by { |holiday| holiday['date'] }
    rescue KeyError, ArgumentError, TypeError
      raise Error, 'invalid_response'
    end

    private

    def request(path)
      uri = URI("#{BASE_URL}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 5
      http.read_timeout = 10
      response = http.get(uri.request_uri, 'Accept' => 'application/json')
      raise Error, 'unavailable' unless response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    rescue JSON::ParserError, TypeError
      raise Error, 'invalid_response'
    rescue Timeout::Error, SocketError, SystemCallError, IOError, OpenSSL::SSL::SSLError, Net::ProtocolError
      raise Error, 'unavailable'
    end
  end
end
