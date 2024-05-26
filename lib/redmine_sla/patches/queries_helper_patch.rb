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

    module QueriesHelperPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do          
          unloadable
          alias_method :column_value_without_custom_sla_priority_id, :column_value
          alias_method :column_value, :column_value_with_custom_sla_priority_id
        end 
      end
    end

    module InstanceMethods

      def column_value_with_custom_sla_priority_id(column, item, value, options={})

        content =
          if ( item.is_a?(Issue) || item.is_a?(TimeEntry) ) && ( ! value.nil? )
            case column.name
              when :get_sla_level
                link_to item.get_sla_level.name, sla_level_url(item.get_sla_level, {:only_path => true}) if ! item.get_sla_level.nil?
              when /^issue.get_sla_respect/, /^get_sla_respect/
                content_tag('span', '', :title => value, :class => "icon #{value ? 'icon-ok' : 'icon-not-ok' }")
                # link_to_sla_level(item.get_sla_level) if ! item.get_sla_level.nil?
            end
          end

        # If it's not the sla_priority_id field, then call the old method !
        content.nil? ? column_value_without_custom_sla_priority_id(column, item, value) : content

      end

    end

  end
end