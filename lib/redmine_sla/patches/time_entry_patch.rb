# frozen_string_literal: true

# File: redmine_sla/lib/redmine_sla/patches/time_entry_patch.rb
# Purpose:
#   Extend Redmine's TimeEntry model with SLA-related helper methods.
#   This patch provides:
#     - delegation of SLA level from the associated issue,
#     - dynamic methods to access SLA respect status per SLA type.
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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

require_dependency 'time_entry'

module RedmineSla
  module Patches
    
    # Patch module applied to Redmine's TimeEntry model.
    module TimeEntryPatch

      # Delegates SLA level retrieval to the associated issue.
      def get_sla_level
        issue.get_sla_level
      end

      # The following methods are intentionally commented out.
      # They illustrate potential delegation to the issue for SLA-related data.
      #
      # def get_sla_cache
      #   issue.get_sla_cache
      # end
      #
      # def get_sla_term(sla_type_id)
      #   issue.get_sla_respect(sla_type_id)
      # end
      #
      # def get_sla_spent(sla_type_id)
      #   issue.get_sla_respect(sla_type_id)
      # end
      #
      # def get_sla_respect(sla_type_id)
      #   issue.get_sla_respect(sla_type_id)
      # end
      
      # get_sla_respect_1, get_sla_respect_2, ... one per SLA type, delegating
      # to the associated issue. Resolved generically rather than defined per
      # existing SlaType, so a SlaType created (or deleted) after the server
      # started works immediately.
      SLA_RESPECT_METHOD = /\Aget_sla_respect_(\d+)\z/

      def method_missing(method_name, *args, &block)
        if (match = SLA_RESPECT_METHOD.match(method_name.to_s))
          return issue.get_sla_respect(match[1].to_i)
        end
        super
      end

      def respond_to_missing?(method_name, include_private = false)
        SLA_RESPECT_METHOD.match?(method_name.to_s) || super
      end

    end

  end
end