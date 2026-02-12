# frozen_string_literal: true

# File: redmine_sla/test/application_documentation_test_case.rb
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

require_relative 'helpers/sla_test_helper'
require_relative 'helpers/sla_documentation_helper'

class ApplicationSlaDocumentationTestCase < ApplicationSystemTestCase

  include Redmine::I18n
  include SlaDocumentationHelperTest

  i_suck_and_my_tests_are_order_dependent!

  # Explicitly enable transactional tests for unit tests
  self.use_transactional_tests = false  

  # Use only the plugin fixtures directory (compatible with Redmine 5 & 6)
  RedmineSlaTestHelper.set_fixture_paths!(self)

  # Redmine 6 may set `fixtures :all` globally; reset and use an explicit list
  self.fixture_table_names = [] if respond_to?(:fixture_table_names=)

  # Load only the fixture sets defined by the plugin bootstrap
  fixtures(*RedmineSlaTestBootstrap.fixture_names(include_sla: false))

end