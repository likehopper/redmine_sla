# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

require_relative '../icon_set'

module RedmineSla
  module Helpers
    module SlaIconsHelper
      def sla_icon_set
        @sla_icon_set ||= IconSet.fetch(Setting.plugin_redmine_sla['sla_icon_set'])
      end

      # Core action icons retain Redmine's rendering. SLA icons follow the selected set.
      def sla_icon(name, label = nil, icon_only: false, size: nil, context: :menu, plugin: nil)
        # Core icons also default to the context size (16px in lists) to match SLA icons.
        size ||= IconSet::CONTEXT_SIZES.fetch(context)
        if plugin.nil? && respond_to?(:sprite_icon)
          return sprite_icon(name, label, icon_only: icon_only, size: size)
        end

        asset = plugin ? sla_icon_set.resolve(name, size: size) : IconSet.core_icon(name)
        icon = if asset&.image?
                 image_tag(asset.path, plugin: 'redmine_sla', width: size, height: size,
                           alt: '', class: 'sla-icon-image', 'aria-hidden': true)
               elsif asset
                 sla_svg_icon(asset.path, asset.symbol, size)
               else
                 ''.html_safe
               end
        return icon unless label

        safe_join([icon, content_tag(:span, label, class: icon_only ? 'sla-icon-label-hidden' : 'sla-icon-label')])
      end

      def sla_icon_credit
        credit = sla_icon_set.credit
        return unless credit['display'] == true

        parts = []
        parts << (credit['text_key'] ? l(credit['text_key']) : credit['text'])
        source = credit['source']
        if credit['logo']
          logo = image_tag(sla_icon_set.asset_path(credit['logo']), plugin: 'redmine_sla', width: 16, height: 16, alt: '', class: 'sla-credit-logo')
          parts << (source ? link_to(logo, source.fetch('url'), title: source.fetch('name')) : logo)
        end
        %w[author source].each do |key|
          entry = credit[key]
          parts << link_to(entry.fetch('name'), entry.fetch('url')) if entry
        end
        content_tag(:div, safe_join(parts.compact, ' '), class: 'redmine_sla_footer')
      end

      # Explicit SVG attributes also support Redmine 5, which has no sprite CSS/helper.
      def sla_svg_icon(file, symbol, size)
        source = if respond_to?(:sprite_icon)
                   "plugin_assets/redmine_sla/#{file}"
                 else
                   "/plugin_assets/redmine_sla/images/#{file}"
                 end
        href = "#{image_path(source)}#icon--#{symbol}"
        content_tag(:svg, content_tag(:use, '', 'href': href, 'xlink:href': href),
                    xmlns: 'http://www.w3.org/2000/svg', 'xmlns:xlink': 'http://www.w3.org/1999/xlink',
                    width: size, height: size, viewBox: '0 0 24 24', fill: 'none',
                    stroke: 'currentColor', 'stroke-width': 2, 'aria-hidden': true,
                    class: "sla-icon-svg s#{size}")
      end
    end
  end
end
