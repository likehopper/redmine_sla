# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Redmine SLA - service level agreement plugin
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

# File: redmine_sla/lib/redmine_sla/native_query_columns.rb
# Purpose:
#   Provide native query joins and consistent SLA grouping keys.
#
# Redmine SLA - Redmine's Plugin

module RedmineSla
  module NativeQueryColumns
    def self.respect_expression(type_id)
      "CASE WHEN sla_query_term_#{type_id}.term IS NULL OR sla_query_spent_#{type_id}.spent IS NULL THEN 0 " \
        "WHEN sla_query_term_#{type_id}.term < sla_query_spent_#{type_id}.spent THEN 1 ELSE 2 END"
    end

    def joins_for_order_statement(order_options)
      joins = [super]
      statement = order_options.to_s
      type_ids = statement.scan(/\bsla_query_(?:term|spent)_(\d+)\b/).flatten.uniq
      if statement.include?('sla_query_level.') || type_ids.any?
        joins << "LEFT JOIN sla_caches AS sla_query_level_cache ON sla_query_level_cache.issue_id = issues.id"
        joins << "LEFT JOIN sla_levels AS sla_query_level ON sla_query_level.id = sla_query_level_cache.sla_level_id"
      end
      if type_ids.any?
        joins << "LEFT JOIN custom_values AS sla_query_priority_value " \
                 "ON sla_query_priority_value.custom_field_id = sla_query_level.custom_field_id " \
                 "AND sla_query_priority_value.customized_id = issues.id " \
                 "AND sla_query_priority_value.customized_type = 'Issue'"
        type_ids.each { |type_id| joins << sla_respect_joins(type_id.to_i) }
      end
      joins.compact.join(' ').presence
    end

    def result_count_by_group
      map_sla_group_keys(super)
    end

    def total_by_group_for(column)
      map_sla_group_keys(super)
    end

    private

    def map_sla_group_keys(values)
      return values unless values.is_a?(Hash) && group_by.to_s.match?(/\Aget_sla_respect_\d+\z/)

      values.each_with_object({}) do |(key, value), groups|
        respect = {0 => nil, 1 => false, 2 => true}[key.to_i]
        groups[respect] = (groups[respect] || 0) + value
      end
    end

    # Explicit reference joins keep group expressions compatible with strict
    # MySQL without materializing SLA values for every issue in a derived table.
    # The native query retains its visibility, project and filter predicates.
    def sla_respect_joins(type_id)
      <<~SQL.squish
        LEFT JOIN sla_cache_spents AS sla_query_spent_#{type_id}
          ON sla_query_spent_#{type_id}.sla_cache_id = sla_query_level_cache.id
          AND sla_query_spent_#{type_id}.sla_type_id = #{type_id}
        LEFT JOIN sla_level_terms AS sla_query_term_#{type_id}
          ON sla_query_term_#{type_id}.sla_level_id = sla_query_level_cache.sla_level_id
          AND sla_query_term_#{type_id}.sla_type_id = #{type_id}
          AND sla_query_term_#{type_id}.sla_priority_id = CASE
            WHEN sla_query_level.custom_field_id IS NULL THEN issues.priority_id
            ELSE CAST(sla_query_priority_value.value AS #{RedmineSla::DbDialect.bigint_cast_type})
          END
      SQL
    end
  end
end
