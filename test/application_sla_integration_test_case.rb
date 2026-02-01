# frozen_string_literal: true

# File: redmine_sla/test/application_sla_integration_test_case.rb
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
require_relative 'helpers/sla_object_helper'

class ApplicationSlaIntegrationTestCase < Redmine::IntegrationTest
  
  include Redmine::I18n
  
  include RedmineSlaTestBootstrap
  
  # Functional tests run in-process, but we keep the same behavior as units/system
  self.use_transactional_tests = true  

  # Force plugin-only fixtures directory (works on Redmine 5 & 6)
  RedmineSlaTestHelper.set_fixture_paths!(self)

  # Load only the fixture sets defined by the plugin bootstrap
  fixtures(*RedmineSlaTestBootstrap.fixture_names(include_sla: true))

  # Variable de classe pour suivre l'état du calcul
  # @@sla_update_done = false

  def setup_fixtures
    super
    # On ne l'exécute que si ça n'a pas encore été fait pour cette session
    # unless @@sla_update_done
      RedmineSlaTestBootstrap.ensure_update_sla!
      # @@sla_update_done = true
    # end
  end

end