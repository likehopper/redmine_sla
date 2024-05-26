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

require_dependency 'time_entry'

module RedmineSla

  module Patches
    
    module TimeEntryPatch

      def get_sla_level
        issue.get_sla_level
      end

      # def get_sla_cache
      #   issue.get_sla_cache
      # end

      # def get_sla_term(sla_type_id)
      #   issue.get_sla_respect(sla_type_id)
      # end
      
      # def get_sla_spent(sla_type_id)
      #   issue.get_sla_respect(sla_type_id)
      # end

      # def get_sla_respect(sla_type_id)
      #   issue.get_sla_respect(sla_type_id)
      # end
      
      if ActiveRecord::Base.connection.table_exists? 'sla_types'
        SlaType.all.each { |sla_type|       
          define_method("get_sla_respect_#{sla_type.id}") do 
            self.issue.get_sla_respect(sla_type.id)
          end
        }
      end

    end

  end

end