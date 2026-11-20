# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

module RedmineSla
  module Patches
    # Decorate only the HTML header; keep captions plain for selectors and exports.
    module ColumnHeadersPatch
      def column_header(query, column, options = {})
        header = super
        role = sla_column_role(column.name)
        return header unless role

        icon = sla_icon(role, context: :column, plugin: 'redmine_sla')
        header.sub(/<th\b[^>]*>/) { |opening| "#{opening}#{icon} " }.html_safe
      end

      private

      def sla_column_role(name)
        case name.to_s
        when 'get_sla_level', 'sla_level' then 'sla_level'
        when 'spent' then 'sla_spent'
        when /\Aget_sla_(spent|term|remain|respect)_\d+\z/ then "sla_#{Regexp.last_match(1)}"
        end
      end

    end
  end
end
