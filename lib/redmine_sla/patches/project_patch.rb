# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

# File: redmine_sla/lib/redmine_sla/patches/project_patch.rb
# Purpose:
#   - Purge a project's SLA cache when its SLA module is disabled.
#     The project's SLA configuration (sla_project_trackers) is kept, so
#     re-enabling the module restores it; only the derived, recomputable
#     cache is removed. The sla_get_level SQL function refuses to calculate
#     anything for such a project, so the cache is not rebuilt meanwhile.
#   - Extend Redmine's Project model with the SLA associations and the
#     permission check used by the project lists (projects#index and
#     admin#projects) to show which projects have SLAs defined.
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

require_dependency 'project'

module RedmineSla
  module Patches

    # Patch module prepended to Redmine's Project model.
    module ProjectPatch

      def self.prepended(base)
        base.class_eval do
          # No dependent option: SlaProjectTracker lifecycle stays managed
          # by the plugin (cache invalidation callbacks).
          has_many :sla_project_trackers
        end
      end

      # Project settings form and REST API. Removed modules are deleted with
      # delete_all (has_many dependent: :delete_all), bypassing EnabledModule
      # callbacks, hence the hook on the setter itself.
      def enabled_module_names=(module_names)
        purge_sla_cache_if_module_disabled { super }
      end

      def disable_module!(target)
        purge_sla_cache_if_module_disabled { super }
      end

      # True when the user may see the SLA configuration of this project.
      # Administrators see every project, others need :view_sla or
      # :manage_sla (which also requires the SLA module to be enabled).
      def sla_visible?(user = User.current)
        return false unless user
        return true if user.admin?

        user.allowed_to?(:view_sla, self) || user.allowed_to?(:manage_sla, self)
      end

      # SLAs assigned to this project (through its trackers), sorted by name
      # and without duplicates. Empty when the user may not see them.
      # Relies on preloaded sla_project_trackers when available.
      def visible_slas(user = User.current)
        return [] unless sla_visible?(user)

        sla_project_trackers.map(&:sla).compact.uniq.sort_by { |sla| sla.name.to_s.downcase }
      end

      private

      def purge_sla_cache_if_module_disabled
        sla_was_enabled = persisted? && sla_module_persisted?
        result = yield
        # sla_cache_spents are removed by the database foreign key cascade.
        SlaCache.purge(self) if sla_was_enabled && !sla_module_persisted?
        result
      end

      # Read from the database: the in-memory enabled_modules target is not
      # updated when disable_module! destroys a record directly.
      def sla_module_persisted?
        EnabledModule.where(project_id: id, name: 'sla').exists?
      end

    end

  end
end
