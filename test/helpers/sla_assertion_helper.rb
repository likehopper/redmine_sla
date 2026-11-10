# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

# File: redmine_sla/test/helpers/sla_assertion_helper.rb
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

module SlaAssertionHelperTest

  def assert_select_not(selector, attributes = {}, message = nil)
    attribute_selector = attributes.map { |key, value| "[#{key}=\"#{value}\"]" }.join
    assert_select "#{selector}#{attribute_selector}", 0, message
  end

  # Anonymous users are sent to the login page, logged-in users get 403.
  def assert_access_denied(user_id)
    if user_id
      assert_response :forbidden
    else
      assert_redirected_to %r{#{signin_path}}
    end
  end

  # Runs denied requests as user_id and checks they changed neither the
  # record nor the number of records of its class.
  def assert_denied_without_change(user_id, record, &requests)
    @request.session[:user_id] = user_id
    attributes_before = record.reload.attributes
    assert_no_difference -> { record.class.count }, &requests
    assert_equal attributes_before, record.reload.attributes
  end

end
