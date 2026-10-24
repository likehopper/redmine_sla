# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

# File: redmine_sla/lib/redmine_sla/patches/project_query_patch.rb
# Purpose:
#   Patch Redmine's ProjectQuery (and therefore ProjectAdminQuery) to add:
#     - an "SLA" column listing the SLAs assigned to each project,
#     - an "SLA" filter (any / none / is / is not) on those assignments.
#
#   Both are offered on projects#index (list display) and admin#projects.
#   In the board display, SLA assignments are preloaded for the SLA icon
#   rendered next to project names (see ProjectPatch#css_classes).
#   Non-admin users only see SLA data for projects where they have the
#   :view_sla or :manage_sla permission; other projects behave as if they
#   had no SLA so that the filter never discloses hidden configuration.

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

require_dependency 'project_query'

module RedmineSla
  module Patches

    # Prepended to ProjectQuery.
    module ProjectQueryPatch

      # Query column rendering the SLAs visible for each project.
      class SlasQueryColumn < QueryColumn
        def initialize
          super(:slas, caption: :sla_label_abbreviation)
        end

        def value_object(project)
          project.visible_slas
        end

        def value(project)
          value_object(project)
        end
      end

      def initialize_available_filters
        super
        return unless sla_available_for_user?

        add_available_filter(
          'sla_id',
          type: :list_optional,
          label: :sla_label_abbreviation,
          values: lambda { project_sla_values }
        )
      end

      def available_columns
        return @available_columns if @available_columns

        super
        @available_columns << SlasQueryColumn.new if sla_available_for_user?
        @available_columns
      end

      def results_scope(options = {})
        scope = super
        return scope unless sla_available_for_user?

        # Both displays need enabled modules for per-project permissions.
        if display_type == 'board'
          scope.preload(:sla_project_trackers, :enabled_modules)
        elsif has_column?(:slas)
          scope.preload(:enabled_modules, sla_project_trackers: :sla)
        else
          scope
        end
      end

      # SQL for the "SLA" filter. A project matches "any" (*) or "is" (=)
      # only when it has a matching assignment AND the user may see it.
      def sql_for_sla_id_field(_field, operator, value)
        assignment_table = SlaProjectTracker.table_name
        condition = "EXISTS (SELECT 1 FROM #{assignment_table} WHERE #{assignment_table}.project_id = #{Project.table_name}.id"
        if %w[= !].include?(operator)
          sla_ids = Array(value).map(&:to_i)
          condition += sla_ids.empty? ? ' AND 1=0' : " AND #{assignment_table}.sla_id IN (#{sla_ids.join(',')})"
        end
        condition += ')'

        visibility_condition = sla_project_visibility_condition
        condition = "(#{condition} AND #{visibility_condition})" if visibility_condition

        %w[! !*].include?(operator) ? "(NOT #{condition})" : condition
      end

      # Administrators get every SLA; other users get visible assignments only.
      def project_sla_values
        scope = Sla.order(:name)
        visibility_condition = sla_project_visibility_condition
        if visibility_condition
          project_ids = Project.where(visibility_condition).select(:id)
          scope = scope.where(id: SlaProjectTracker.where(project_id: project_ids).select(:sla_id))
        end
        scope.pluck(:name, :id).map { |name, id| [name, id.to_s] }
      end

      private

      # The column and filter are only offered to users who can see SLAs
      # in at least one project.
      def sla_available_for_user?(user = User.current)
        user.admin? ||
          user.allowed_to?(:view_sla, nil, global: true) ||
          user.allowed_to?(:manage_sla, nil, global: true)
      end

      # nil for administrators (no restriction), SQL condition otherwise.
      def sla_project_visibility_condition(user = User.current)
        return nil if user.admin?

        "((#{Project.allowed_to_condition(user, :view_sla)}) OR " \
          "(#{Project.allowed_to_condition(user, :manage_sla)}))"
      end

    end
  end
end
