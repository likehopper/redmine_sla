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

      def sla_get_level
        sla_cache = SlaCache.find_or_new(issue_id)
        if ( sla_cache.nil? )
          return nil
        end        
        return sla_cache.sla_level[:name]
      end

      def sla_get_respect(param_time_entry_id,param_sla_type_id)
        time_entry = TimeEntry.find(param_time_entry_id)
        sla_cache = SlaCache.find_or_new(time_entry.issue_id)
        if ( sla_cache.nil? )
          return nil
        end
        sla_level_term = SlaLevelTerm.find_by_level_type(sla_cache.sla_level_id,param_sla_type_id,sla_cache.issue.priority_id)
        if ( sla_level_term.nil? )
          return nil
        end
        sla_term = sla_level_term[:term]  
        sla_cache_spent = SlaCacheSpent.find_or_new(sla_cache.id,param_sla_type_id)
        sla_spent = sla_cache_spent[:spent]     
        return ( ( sla_term - sla_spent ) > 0 )
      end
      
      if ActiveRecord::Base.connection.table_exists? 'sla_types'
        SlaType.all.each { |sla_type|
          define_method("sla_get_respect_#{sla_type.id}") do 
            sla_get_respect(id,sla_type.id)
          end
        }
      end

    end

  end

end

#unless Issue.included_modules.include? RedmineSla::Patches::TimeEntryPatch
#  TimeEntry.send(:include, RedmineSla::Patches::TimeEntryPatch)
#end
