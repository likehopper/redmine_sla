# frozen_string_literal: true

# File: redmine_sla/lib/redmine_sla/patches/issue_patch.rb
# Purpose:
#   Extend Redmine's Issue model with helper methods used by the SLA plugin:
#     - access to the SLA cache and level,
#     - calculation of SLA terms, spent time and remaining time,
#     - boolean SLA respect flag,
#     - dynamic helper methods per SLA type,
#     - automatic SLA cache refresh when project or tracker changes.
#
# Redmine SLA - Redmine Plugin 
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
    
    # Patch module applied to Redmine's Issue model.
    module IssuePatch

      # Used in IssueQueryPatch and in sla_issues_helper/_show to display the
      # SLA level in list columns.
      #
      # Examples:
      #   self.get_sla_cache.sla_level
      #     → "to_s" on sla_level returns the name by default
      #
      #   self.get_sla_cache.sla_level[:id]
      #   self.get_sla_cache.sla_level[:name]
      def get_sla_cache
        SlaCache.find_by_issue_id(id)
      end

      # Returns the SLA level associated with the current issue, if any.
      def get_sla_level
        self.get_sla_cache.sla_level if ! self.get_sla_cache.nil?
      end

      # Returns the expected SLA delay (term) for a given SLA type.
      def get_sla_term(sla_type_id)
        sla_level_term = SlaLevelTerm.find_by_issue_and_type_id(self,sla_type_id)
        sla_level_term.term if ! sla_level_term.nil? 
      end

      # Returns the effective SLA time spent for a given SLA type.
      def get_sla_spent(sla_type_id)
        sla_cache_spent = SlaCacheSpent.find_by_issue_and_type_id(self,sla_type_id)
        sla_cache_spent.spent if ! sla_cache_spent.nil? && ! self.get_sla_term(sla_type_id).nil?
      end

      # Used in IssueQueryPatch to display SLA remaining time in list columns.
      def get_sla_remain(sla_type_id)
        sla_term = self.get_sla_term(sla_type_id)
        # TODO: SlaLog: handle missing sla_level

        sla_spent = self.get_sla_spent(sla_type_id)
        # TODO: SlaLog: handle nil/zero spent values

        ( sla_term - sla_spent ) if sla_term && sla_spent
      end      

      # Used in IssueQueryPatch to display SLA respect (boolean) in list columns.
      #
      # Returns:
      #   - true  if SLA is respected
      #   - false if SLA is violated (spent strictly greater than term)
      #   - nil   if SLA data is incomplete
      def get_sla_respect(sla_type_id)
        sla_term = self.get_sla_term(sla_type_id)
        sla_spent = self.get_sla_spent(sla_type_id)

        # Added .to_i conversion to ensure numerical comparison
        if sla_term && sla_spent
          term_i = sla_term.to_i
          spent_i = sla_spent.to_i
          
          # Logic: respected if term is not strictly less than spent.
          ( ! ( term_i < spent_i ) )
        else
          nil # Returns nil if the SLA data is missing
        end
      end      

      # For SlaCacheQuery#group_by:
      # Dynamically define convenience methods on Issue such as:
      #   get_sla_respect_1, get_sla_respect_2, ...
      # one per SLA type, to simplify grouping and display logic.
      #
      # Database access is wrapped in a begin/rescue to avoid errors when
      # the database is not yet available (e.g. during installation).
      begin
        if ActiveRecord::Base.connection.table_exists? 'sla_types'
          SlaType.all.each { |sla_type|
            define_method("get_sla_respect_#{sla_type.id}") do 
              self.get_sla_respect(sla_type.id)
            end
          }
        end
      rescue ActiveRecord::NoDatabaseError, PG::ConnectionBad
        # Skip the dynamic method definition if the database connection fails
      end
      
      # Trigger to update sla_cache when necessary.
      #
      # This hook is called when the module is included into Issue:
      #   - extends the base with ClassMethods
      #   - includes InstanceMethods
      #   - registers an after_save callback to refresh SLA cache when
      #     project or tracker changes.
      def self.included(base)
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
          # After issue update, if project or tracker changed then refresh sla_cache !!!
          after_save :sla_cache_update
        end
      end

    end

    module ClassMethods
    end

    module InstanceMethods
      # Refresh SLA cache after an issue is updated, if project or tracker changed.
      def sla_cache_update
        # If project or tracker changed then the SLA cache must be refreshed
        unless ( self.project_id == self.project_id_before_last_save && self.tracker_id == self.tracker_id_before_last_save )
          SlaCache.find(self.id).refresh
        end
      rescue ActiveRecord::RecordNotFound
        # Ignore missing SLA cache entries
      end
    end

  end

end