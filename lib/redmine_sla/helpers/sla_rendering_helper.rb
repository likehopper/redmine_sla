# frozen_string_literal: true

# File: redmine_sla/lib/redmine_sla/sla_rendering_helper.rb
# Purpose:
#   Provide view helpers for SLA rendering in Redmine, especially for
#   generating SLA compliance icons in issue views or reports.
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

module RedmineSla
  module Helpers
    # Rendering helpers for SLA display logic.
    # Placed under a dedicated submodule for clarity.
    module SlaRenderingHelper
      include ActionView::Helpers::TagHelper

      # Generates the HTML tag for an SLA compliance icon.
      #
      # Parameters:
      #   respect_status (Boolean or nil)
      #     - true  → SLA respected
      #     - false → SLA violated
      #     - nil   → no icon displayed
      #
      # Returns:
      #   HTML-safe <span> tag containing a contextual icon.
      #
      # Notes:
      #   - Uses Redmine's built-in "icon" CSS classes.
      #   - `raw('&nbsp;')` ensures icon alignment on certain Redmine themes.
      #   - The icon includes a tooltip (title) for accessibility.
      def sla_respect_icon_tag(respect_status)
        return if respect_status.nil?

        icon_class = respect_status ? 'icon-ok' : 'icon-not-ok'
        text       = respect_status ? l(:general_text_Yes) : l(:general_text_No)

        # The content_tag creates a <span> element with:
        #   - a forced non-breaking space for visual rendering,
        #   - a CSS icon class,
        #   - a tooltip containing localized text.
        content_tag(
          'span',
          raw('&nbsp;'),
          title: text,
          class: "icon #{icon_class}"
        )
      end
    end
  end
end