# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

# File: redmine_sla/lib/redmine_sla/hooks/views_layouts_hook.rb
# Purpose:
#   Register a layout-level view hook that injects the plugin's assets into
#   Redmine's global layout (<head> section).

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
    # Layout hook used to inject the plugin assets in the global layout.
    # The hook is called when rendering the <head> section of Redmine's layout.
    class ViewsLayoutsHook < Redmine::Hook::ViewListener

      # Called by Redmine in the <head> section of the base layout.
      # Returns:
      #   HTML tags referencing the plugin stylesheet and JavaScript.
      def view_layouts_base_html_head(context = {})
        safe_join([
          stylesheet_link_tag(:redmine_sla, plugin: 'redmine_sla'),
          javascript_include_tag(:redmine_sla, plugin: 'redmine_sla')
        ], "\n")
      end
    end
  end
end
