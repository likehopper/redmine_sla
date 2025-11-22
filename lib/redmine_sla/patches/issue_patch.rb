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

      # Use in IssueQueryPatch and sla_issues_helper/_show for diplay level in list column level
      #   self.get_sla_cache.sla_level => method "to_s" display [:name] by default
      #   self.get_sla_cache.sla_level[:id] &  self.get_sla_cache.sla_level[:name]
      def get_sla_cache
        SlaCache.find_by_issue_id(id)
      end

      def get_sla_level
        self.get_sla_cache.sla_level if ! self.get_sla_cache.nil?
      end

      # The expected SLA's delay
      def get_sla_term(sla_type_id)
        sla_level_term = SlaLevelTerm.find_by_issue_and_type_id(self,sla_type_id)
        sla_level_term.term if ! sla_level_term.nil? 
      end

      # The effective SLA's delay
      def get_sla_spent(sla_type_id)
        sla_cache_spent = SlaCacheSpent.find_by_issue_and_type_id(self,sla_type_id)
        sla_cache_spent.spent if ! sla_cache_spent.nil? && ! self.get_sla_term(sla_type_id).nil?
      end

      # Use in IssueQueryPatch for diplay respect in list column level
      def get_sla_remain(sla_type_id)
        sla_term = self.get_sla_term(sla_type_id)
        # TODO : SlaLog : no sla_level

        sla_spent = self.get_sla_spent(sla_type_id)
        # TODO : SlaLog : si valeur nulle

        ( sla_term - sla_spent ) if sla_term && sla_spent
      end      

      # Use in IssueQueryPatch for diplay respect in list column level
      def get_sla_respect(sla_type_id)
        sla_term = self.get_sla_term(sla_type_id)
        # TODO : SlaLog : no sla_level

        sla_spent = self.get_sla_spent(sla_type_id)
        # TODO : SlaLog : si valeur nulle

        ( ! ( sla_term < sla_spent ) ) if sla_term && sla_spent
      end

      # For SlaCacheQuery#GRoupBy
      if ActiveRecord::Base.connection.table_exists? 'sla_types'
        SlaType.all.each { |sla_type|
          define_method("get_sla_respect_#{sla_type.id}") do 
            self.get_sla_respect(sla_type.id)
          end
        }
      end
      
      # Trigger for update sla_cache if necessary
      def self.included(base)
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable if defined?(Rails) && !Rails.autoloaders.zeitwerk_enabled?
          # After issue update, if project or tracker changed then refresh sla_cache !!!
          after_save :sla_cache_update
        end
      end

    end

    module ClassMethods
    end

    module InstanceMethods
      def sla_cache_update
        # if project or tracker changed then must refresh sla_cache
        unless ( self.project_id == self.project_id_before_last_save && self.tracker_id == self.tracker_id_before_last_save )
          SlaCache.find(self.id).refresh
        end
      rescue ActiveRecord::RecordNotFound
      end
    end

  end

end