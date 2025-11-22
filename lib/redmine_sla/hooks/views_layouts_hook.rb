# frozen_string_literal: true

# File: redmine_sla/lib/redmine_sla/views_layouts_hook.rb
# Purpose:
#   Register a layout-level view hook that injects the plugin's stylesheet
#   into Redmine's global layout (<head> section), so SLA-specific styles are
#   available across all pages.

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
    # Layout hook used to inject the plugin stylesheet in the global layout.
    # The hook is called when rendering the <head> section of Redmine's layout.
    class ViewsLayoutsHook < Redmine::Hook::ViewListener

      # Called by Redmine in the <head> section of the base layout.
      # Returns:
      #   An HTML <link> tag referencing the plugin stylesheet:
      #     public/plugin_assets/redmine_sla/stylesheets/redmine_sla.css
      def view_layouts_base_html_head(context = {})
        return stylesheet_link_tag(:redmine_sla, plugin: 'redmine_sla')
      end
    end
  end
end