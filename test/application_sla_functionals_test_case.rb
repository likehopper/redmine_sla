# frozen_string_literal: true

# File: redmine_sla/test/application_functionals_test_case.rb
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
require_relative 'helpers/sla_assertion_helper'

class ApplicationSlaFunctionalsTestCase < Redmine::ControllerTest

  include Redmine::I18n

  include RedmineSlaTestBootstrap
  include SlaAssertionHelperTest
  
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
    
    # unless @@sla_update_done
    #   # 1. On sort de la transaction actuelle (celle des fixtures)
    #   if ActiveRecord::Base.connection.transaction_open?
    #     ActiveRecord::Base.connection.commit_db_transaction
    #   end

    #   # 2. On exécute le calcul SLA
      RedmineSlaTestBootstrap.ensure_update_sla!
      
    #   # 3. On force l'écriture finale
    #   ActiveRecord::Base.connection.execute("COMMIT") 
      
    #   # 4. L'ASTUCE : On réouvre une transaction pour que Rails 
    #   # puisse créer ses SAVEPOINTS (utilisés par with_settings)
    #   ActiveRecord::Base.connection.begin_db_transaction
      
    #   @@sla_update_done = true
    # end
    
  end

  # def setup
  #   super
  #   puts ""
  #   puts ">>> Verification SQL sla_cache : #{ActiveRecord::Base.connection.execute("SELECT count(*) FROM sla_caches").first}"
  #   puts ">>> Verification SQL sla_cache_spent : #{ActiveRecord::Base.connection.execute("SELECT count(*) FROM sla_cache_spents").first}"    
  # end

end