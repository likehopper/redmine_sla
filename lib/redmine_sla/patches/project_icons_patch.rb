# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

module RedmineSla
  module Patches
    # The board already supplies the permission-aware has-sla class.
    module ProjectIconsPatch
      def link_to_project(project, options = {}, html_options = nil)
        link = super
        return link unless html_options && html_options[:class].to_s.split.include?('has-sla')
        return link unless link.end_with?('</a>')

        icon = content_tag(:span, sla_icon('sla', context: :list, plugin: 'redmine_sla'), class: 'sla-project-marker')
        link.sub(%r{</a>\z}) { "#{icon}</a>" }.html_safe
      end
    end
  end
end
