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

require File.expand_path('../../application_sla_units_test_case', __FILE__)

class SlaCustomFieldTest < ApplicationSlaUnitsTestCase

  def with_captured_log
    original_logger = Rails.logger
    io = StringIO.new
    Rails.logger = Logger.new(io)
    yield
    io.string
  ensure
    Rails.logger = original_logger
  end

  test "find logs an error when no matching enumeration custom field exists" do
    log = with_captured_log { SlaCustomField.find(-1) }
    assert_nil SlaCustomField.find(-1)
    assert_match(/no matching enumeration custom field for id=-1/, log)
  end

  test "all logs a warning when no enumeration custom field is available" do
    IssueCustomField.where(field_format: :enumeration, multiple: :false, is_required: true).delete_all
    log = with_captured_log { SlaCustomField.all }
    assert_match(/no enumeration custom field available/, log)
  end

end
