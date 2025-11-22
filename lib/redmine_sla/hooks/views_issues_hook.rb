# frozen_string_literal: true

# File: redmine_sla/lib/redmine_sla/views_issues_hook.rb
# Purpose:
#   Define Redmine view hooks used by the SLA plugin. This hook injects
#   SLA rendering logic into the issue details view, allowing SLA-related
#   information to be displayed directly in the issue UI.

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
  module Hooks

    # Listener hooking into Redmine's issue view rendering.
    # It allows the plugin to inject SLA information in the issue UI,
    # specifically at the bottom of the "details" section.
    class ViewsIssuesHook < Redmine::Hook::ViewListener

      # Injects the partial:
      #   redmine_sla/app/views/sla_issues_helper/_show.html.erb
      #
      # into:
      #   view_issues_show_details_bottom
      #
      # This is where SLA-related information (timing, levels, compliance...)
      # is displayed in the issue details screen.
      render_on :view_issues_show_details_bottom,
                partial: "sla_issues_helper/show"

    end
  end
end