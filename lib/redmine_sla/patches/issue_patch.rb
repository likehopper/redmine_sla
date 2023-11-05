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

require_dependency 'issue'

module RedmineSla

  module Patches
    
    # Patches Redmine's IssuesController dynamically
    module IssuePatch

      # Use in IssueQueryPatch for diplay level in list column level
      def sla_get_level
        sla_cache = SlaCache.find_or_new(id)
        if ( sla_cache.nil? )
          return nil
        end        
        return sla_cache.sla_level[:name]
      end

      def sla_get_respect(param_issue_id,param_sla_type_id)
        sla_cache = SlaCache.find_or_new(param_issue_id)
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
          Rails.logger.debug "==>> IssuePatch InstanceMethods sla_get_respect_#{sla_type.id} for #{sla_type.name.to_sym} <<==="
          define_method("sla_get_respect_#{sla_type.id}") do 
            sla_get_respect(id,sla_type.id)
          end
        }
      end
      
      def self.included(base) # :nodoc:
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
        # Same as typing in the class
        base.class_eval do
          unloadable
          # TODO: After the update, if a criterion changes (tracker / priority) then we recalculate!!!
          after_save :sla_cache_update
          #after_destroy :sla_cache_destroy # made in database by FOREIGN KEY (issue_id) REFERENCES issues(id) ON DELETE CASCADE
        end
      end
    end

    module ClassMethods
    end

    module InstanceMethods

      def sla_cache_update
        sla_level_changed = false
        # if tracker changed then must change sla_level in sla_cache
        if ( self.tracker_id != self.tracker_id_before_last_save ) then
          sla_level_changed = true
        end
        # if priority changed then must change sla_level in sla_cache
        if ( self.priority_id != self.priority_id_before_last_save ) then
          sla_level_changed = true
        end
        # if a change require then clear cache for issue
        if ( sla_level_changed ) then
          SlaCache.destroy_by_issue_id(self.id)
        end
        # The update is useless since called by view
        #SlaCache.new.refresh_by_issue_id(self.id) 
        return true
      end

    end

  end

end

#unless Issue.included_modules.include? RedmineSla::Patches::IssuePatch
#  Issue.send(:include, RedmineSla::Patches::IssuePatch)
#end