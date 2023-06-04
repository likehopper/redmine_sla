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

module RedmineSla
  module Patches
    # Project's configuration
    module ProjectsHelperPatch
      # Overload project's configuration tabs                                                                                                                                                                                  
      def project_settings_tabs
        tabs = super
        # Permissions check
        if User.current.allowed_to?(:manage_sla, @project)
          # Create new tab for project's configuration
          tabs << { name: 'slas',
                    action: :manage_sla,
                    partial: 'sla_project_trackers/show',
                    label: :sla_label_project_settings }
        end
        tabs
      end
    end
  end
end