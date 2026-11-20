# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

module RedmineSla
  module Patches
    # Keep native menu routing, selection and permissions; decorate only SLA's entry.
    module AdminMenuIconsPatch
      def render_single_menu_node(item, caption, url, selected)
        return super unless item.name == :redmine_sla && item.url[:controller].to_s.delete_prefix('/') == 'slas'

        size = defined?(IconsHelper::DEFAULT_ICON_SIZE) ? IconsHelper::DEFAULT_ICON_SIZE.to_i : IconSet::CONTEXT_SIZES.fetch(:menu)
        label = sla_icon('sla', caption, context: :menu, size: size, plugin: 'redmine_sla')
        # Redmine 5 has no SVG menu icons: its menu links keep a padding slot for a background icon.
        label = content_tag(:span, label, class: 'sla-legacy-menu-icon') unless respond_to?(:sprite_icon)
        super(item, label, url, selected)
      end
    end
  end
end
