# frozen_string_literal: true

# File: redmine_sla/lib/redmine_sla/patches/queries_helper_patch.rb
# Purpose:
#   Extend Redmine's QueriesHelper so that:
#     - SLA-specific redirect helpers are available for query actions,
#     - SLA-level and SLA-respect columns are rendered with links or icons.
#
#   This patch is used mainly to:
#     - redirect back to the correct SLA resource after query operations,
#     - customize how SLA columns are displayed in issue and time entry lists.

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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

module RedmineSla
  module Patches

    # Patch for Redmine's QueriesHelper
    module QueriesHelperPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.send(:include, RedmineSla::Helpers::SlaRenderingHelper)
        base.class_eval do

          alias_method :column_value_without_custom_sla_priority_id, :column_value
          alias_method :column_value, :column_value_with_custom_sla_priority_id

          # Redirect helpers used from various SLA controllers/queries

          def redirect_to_sla_query(options)
            redirect_to slas_path(options)
          end

          def redirect_to_sla_type_query(options)
            redirect_to sla_types_path(options)
          end

          def redirect_to_sla_status_query(options)
            redirect_to sla_statuses_path(options)
          end

          def redirect_to_sla_calendar_query(options)
            redirect_to sla_calendars_path(options)
          end

          def redirect_to_sla_holiday_query(options)
            redirect_to sla_holidays_path(options)
          end

          def redirect_to_sla_calendar_holiday_query(options)
            redirect_to sla_calendar_holidays_path(options)
          end

          def redirect_to_sla_schedule_query(options)
            redirect_to sla_schedules_path(options)
          end

          def redirect_to_sla_level_query(options)
            redirect_to sla_levels_path(options)
          end

          def redirect_to_sla_level_term_query(options)
            redirect_to sla_level_terms_path(options)
          end

          def redirect_to_sla_project_tracker_query(options)
            if @project
              redirect_to project_sla_project_trackers_path(@project, options)
            else
              redirect_to sla_project_trackers_path(options)
            end
          end

          def redirect_to_sla_cache_query(options)
            Rails.logger.debug "==>> redirect_to_sla_cache_query options=#{options}"
            if @project
              redirect_to project_sla_caches_path(@project, options)
            else
              redirect_to sla_caches_path(options)
            end
          end

          def redirect_to_sla_cache_spent_query(options)
            redirect_to sla_cache_spents_path(options)
          end

        end
      end
    end

    module InstanceMethods

      # Extended column_value to support SLA-specific columns.
      #
      # For:
      #   - :get_sla_level → display a link to the SLA level
      #   - get_sla_respect_* methods → display an SLA respect icon
      #
      # For all other columns, fall back to the original implementation.
      def column_value_with_custom_sla_priority_id(column, item, value, options = {})

        content =
          if (item.is_a?(Issue) || item.is_a?(TimeEntry) || item.is_a?(SlaCache))
            case column.name
            when :get_sla_level
              # Link to the SLA level page when SLA level is present
              link_to(
                item.get_sla_level.name,
                sla_level_url(item.get_sla_level, only_path: true)
              ) if !item.get_sla_level.nil?

            # SLA respect columns for Issue, TimeEntry or SlaCache queries
            when /^get_sla_respect/
              sla_respect_icon_tag(item.send(column.name))
            end
          end

        # If content wasn't handled by SLA logic, call the original method.
        content.nil? ? column_value_without_custom_sla_priority_id(column, item, value) : content
      end

    end

  end
end