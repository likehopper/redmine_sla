# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

# File: redmine_sla/lib/redmine_sla/helpers/sla_rendering_helper.rb
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

      # Maximum length of a description shown as a tooltip.
      SLA_DESCRIPTION_TOOLTIP_LENGTH = 250

      # Plain-text tooltip built from an SLA object's description.
      #
      # Parameters:
      #   object   - any SLA object responding to #description (or nil)
      #   fallback - tooltip to keep when there is no description
      #
      # Returns:
      #   The description rendered with the configured text formatting,
      #   stripped of markup, squished and truncated, or +fallback+.
      #
      # Notes:
      #   - The formatter is called directly instead of `textilizable`, so
      #     no wiki macro or Redmine link is evaluated inside a tooltip.
      #   - Results are cached in this view context by format and source text.
      #     Repeated names share a tooltip; changed descriptions are recomputed.
      #   - A nil return makes Rails omit the `title` attribute.
      def sla_description_tooltip(object, fallback = nil)
        description = object.try(:description)
        return fallback if description.blank?

        @sla_description_tooltips ||= {}
        cache_key = [Setting.text_formatting, description.dup.freeze]
        unless @sla_description_tooltips.key?(cache_key)
          formatted_description = Redmine::WikiFormatting.to_html(cache_key.first, description)
          plain_description = CGI.unescapeHTML(
            ActionView::Base.full_sanitizer.sanitize(formatted_description).to_s
          ).squish
          @sla_description_tooltips[cache_key] = plain_description.presence&.truncate(SLA_DESCRIPTION_TOOLTIP_LENGTH)
        end
        @sla_description_tooltips[cache_key] || fallback
      end

      # An SLA object's name, wrapped in a span carrying its description as
      # a tooltip when it has one. Used where names are displayed as text.
      def sla_name_with_tooltip(object, name = object.name)
        tooltip = sla_description_tooltip(object)
        tooltip ? content_tag('span', name, title: tooltip) : name
      end
    end
  end
end
