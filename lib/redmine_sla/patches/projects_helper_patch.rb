# frozen_string_literal: true

# File: redmine_sla/lib/redmine_sla/patches/projects_helper_patch.rb
# Purpose:
#   Extend Redmine's ProjectsHelper in order to inject an additional
#   configuration tab dedicated to SLA settings in the project settings UI.
#   The tab is only shown if the current user has the :manage_sla permission.

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

module RedmineSla
  module Patches

    # Patch for Redmine's ProjectsHelper
    # Adds a new "SLA" tab to the project settings screen.
    module ProjectsHelperPatch

      # Overrides the default Redmine method to inject an additional tab.
      def project_settings_tabs
        tabs = super

        # Show the tab only if the current user is allowed to manage SLAs
        if User.current.allowed_to?(:manage_sla, @project)
          tabs << {
            name: 'sla',
            action: :manage_sla,
            partial: 'sla_project_trackers/show',
            label: :sla_label_project_settings
          }
        end

        tabs
      end

    end
  end
end