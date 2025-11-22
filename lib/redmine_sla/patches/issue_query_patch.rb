# frozen_string_literal: true

# File: redmine_sla/lib/redmine_sla/patches/issue_query_patch.rb
# Purpose:
#   Patch Redmine's IssueQuery class to add SLA-related:
#     - filters,
#     - dynamic SQL conditions,
#     - sortable/queryable columns,
#     - dynamic methods per SLA type.
#
#   This patch also removes legacy overrides that broke compatibility with
#   modern Redmine versions (5/6) and Rails 6/7, particularly the
#   `sql_for_field_with_sla` alias which previously caused SQL errors.
#
#   All SLA logic injected here affects the Redmine issue list (issues#index)
#   including filtering, grouping, and sorting.

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

require_dependency 'issue_query'

module RedmineSla
  module Patches

    # Patch module applied dynamically to IssueQuery
    module IssueQueryPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          
          alias_method :available_filters_without_sla_issue, :available_filters
          alias_method :available_filters, :available_filters_with_sla_issue

          # --- CRITICAL: remove obsolete sql_for_field_with_sla override -----------
          if self.method_defined?(:sql_for_field)
            # Remove the old alias if it still exists
            undef_method :sql_for_field_with_sla rescue nil

            # Ensure we return to Redmine’s own implementation
            alias_method :sql_for_field, :sql_for_field_without_sla rescue nil
          end
          # --------------------------------------------------------------------------

          # Build SQL condition for SLA “respect” filters
          def sql_for_slas_sla_respect_field(field, operator, value, sla_type_id)
            condition =
              if value.size > 1
                (operator == '!' ?
                  'sla_caches.sla_level_id IS NULL' :
                  'sla_caches.sla_level_id IS NOT NULL')
              else
                is_done_val =
                  value.join == '1' ?
                  self.class.connection.quoted_true :
                  self.class.connection.quoted_false

                # Respect = NOT (term < spent)
                "( ( NOT ( sla_level_terms.term < sla_cache_spents.spent ) ) IS #{is_done_val} )"
              end

            # Subquery building full SLA context
            selection = "
              SELECT DISTINCT issues.id
              FROM issues AS sla_issues
              LEFT JOIN sla_caches ON ( sla_issues.id = sla_caches.issue_id )
              LEFT JOIN sla_levels ON ( sla_caches.sla_level_id = sla_levels.id )
              LEFT JOIN custom_values ON (
                sla_levels.custom_field_id = custom_values.custom_field_id
                AND custom_values.customized_id = issues.id
              )
              LEFT JOIN sla_cache_spents ON (
                sla_caches.id = sla_cache_spents.sla_cache_id
                AND sla_cache_spents.sla_type_id = #{sla_type_id}
              )
              LEFT JOIN sla_level_terms ON (
                sla_caches.sla_level_id = sla_level_terms.sla_level_id
                AND sla_level_terms.sla_type_id = #{sla_type_id}
                AND sla_level_terms.sla_priority_id = (
                  CASE
                    WHEN sla_levels.custom_field_id IS NULL
                      THEN issues.priority_id
                    ELSE CAST(custom_values.value AS BIGINT)
                  END
                )
              )
              WHERE sla_issues.id = issues.id
            "

            "( #{Issue.table_name}.id = ( #{selection} AND #{condition} ) )"
          end

          # SQL generation for filtering by SLA level
          def sql_for_slas_sla_level_id_field(field, operator, value)
            neg  = (operator == '!' ? 'NOT' : '')
            null = (operator == '!' ? 'OR sla_caches.sla_level_id IS NULL' : '')

            condition =
              "( sla_caches.sla_level_id #{neg} IN (#{value.join(',')}) #{null}"

            issue_ids =
              "SELECT DISTINCT issues.id FROM issues
               LEFT JOIN sla_caches ON ( issues.id = sla_caches.issue_id )
               WHERE #{condition}"

            "(#{Issue.table_name}.id IN (#{issue_ids})))"
          end

        end
      end

    end

    # Instance methods injected into IssueQuery
    module InstanceMethods

      # Extends Redmine’s available filters:
      #   - adds SLA level filter + column
      #   - adds SLA respect filters + columns per SLA type
      def available_filters_with_sla_issue
        # Debug tracing
        Rails.logger.error "--- REDMINE_SLA TRACE: available_filters_with_sla_issue CALL ---"

        is_filters_blank = @available_filters.blank?
        is_module_enabled = project&.module_enabled?(:sla)
        is_user_allowed = (
          User.current.admin? ||
          User.current.allowed_to?(:view_sla, project, global: true)
        )

        if is_filters_blank && is_module_enabled && is_user_allowed

          #
          # SLA LEVEL filter + column
          #
          values = SlaLevel
                      .joins(:sla_project_trackers)
                      .where("sla_project_trackers.project_id = ?", project.id)
                      .select("sla_levels.id, sla_levels.name")
                      .distinct
                      .pluck(:name, :id)

          add_available_filter(
            'slas.sla_level_id',
            name:   l("sla_label.sla_level.singular"),
            type:   :list,
            values: values
          ) unless available_filters_without_sla_issue.key?('slas.sla_level_id')

          # SLA Level column
          issue_get_sla_level = QueryColumn.new(
            :get_sla_level,
            caption:     "📢 " + l("sla_label.sla_level.singular"),
            groupable:   true,
            value_object: true,
            sortable:    "(SELECT sla_levels.name FROM sla_caches INNER JOIN sla_levels ON ( sla_caches.sla_level_id = sla_levels.id ) WHERE sla_caches.issue_id = issues.id ORDER BY sla_levels.name)"
          )

          def issue_get_sla_level.group_by_statement
            self.sortable
          end

          self.available_columns << issue_get_sla_level

          #
          # SLA RESPECT filters + dynamic columns (one per SLA type)
          #
          if ActiveRecord::Base.connection.table_exists?('sla_types')

            sla_types_for_project =
              SlaType
                .joins(:sla_project_trackers)
                .where("sla_project_trackers.project_id = ?", project.id)
                .select("sla_types.id, sla_types.name")
                .distinct
                .to_a

            sla_types_for_project.each do |sla_type|

              add_available_filter(
                "slas.sla_respect_#{sla_type.id}",
                name: l(:label_sla_respect) + " " + sla_type.name,
                type: :list,
                values: [[l(:general_text_Yes), '1'], [l(:general_text_No), '0']]
              ) unless available_filters_without_sla_issue.key?("slas.sla_respect_#{sla_type.id}")

              # Dynamic SQL handler for filtering
              if !singleton_methods.include? "sql_for_slas_sla_respect_#{sla_type.id}_field".to_sym
                define_singleton_method("sql_for_slas_sla_respect_#{sla_type.id}_field") do |field, operator, value|
                  sql_for_slas_sla_respect_field(field, operator, value, sla_type.id)
                end
              end

              # SLA RESPECT column
              name_to_sym = "get_sla_respect_#{sla_type.id}".to_sym

              self.available_columns.delete_if { |c| c.name == name_to_sym }

              issue_get_sla_respect = QueryColumn.new(
                name_to_sym,
                caption: "⏰ " + l(:label_sla_respect) + " " + sla_type.name,
                groupable: true,
                value_object: true,
                sortable: "( /* long SQL expression unchanged */ 
                    SELECT DISTINCT CASE
                    WHEN sla_level_terms.term IS NULL THEN 0
                    WHEN ( ( NOT ( sla_level_terms.term < sla_cache_spents.spent ) ) IS NOT TRUE ) THEN 1
                    ELSE 2 END AS sla_respect
                    FROM issues AS sla_issues
                    LEFT JOIN sla_caches ON ( sla_issues.id = sla_caches.issue_id )
                    LEFT JOIN sla_levels ON ( sla_caches.sla_level_id = sla_levels.id )
                    LEFT JOIN custom_values ON ( sla_levels.custom_field_id = custom_values.custom_field_id AND custom_values.customized_id = sla_issues.id )
                    LEFT JOIN sla_cache_spents ON ( sla_caches.id = sla_cache_spents.sla_cache_id AND sla_cache_spents.sla_type_id = #{sla_type.id} )
                    LEFT JOIN sla_level_terms ON ( sla_caches.sla_level_id = sla_level_terms.sla_level_id AND sla_level_terms.sla_type_id = #{sla_type.id}
                      AND sla_level_terms.sla_priority_id = ( CASE
                      WHEN sla_levels.custom_field_id IS NULL THEN sla_issues.priority_id
                      ELSE CAST(custom_values.value AS BIGINT) END
                      )
                    )
                    WHERE sla_issues.id = issues.id
                )"
              )

              def issue_get_sla_respect.group_by_statement
                self.sortable
              end

              self.available_columns << issue_get_sla_respect

            end

          else
            Rails.logger.error "--- REDMINE_SLA TRACE: 'sla_types' table missing, skipping SLA columns ---"
          end

        else
          Rails.logger.error "--- REDMINE_SLA TRACE: EXIT: filters not initialized. ---"
          return available_filters_without_sla_issue
        end

        @available_filters
      end

    end

  end
end