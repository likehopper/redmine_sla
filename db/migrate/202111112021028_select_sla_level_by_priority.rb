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
# File: redmine_sla/db/migrate/202111112021028_select_sla_level_by_priority.rb
# Purpose:
#   Restrict candidate SLA levels to those defining a term for the issue's
#   priority and remove only cached level choices that can consequently change.

class SelectSlaLevelByPriority < ActiveRecord::Migration[5.2]

  def up
    execute "DROP FUNCTION IF EXISTS sla_get_level ;" if RedmineSla::DbDialect.adapter == :mysql
    execute RedmineSla::DbDialect.function_sql('sla_get_level')
    say "Redeployed function sla_get_level"

    delete_caches_without_priority_term
    say "Removed cached levels without a term for the issue priority"
  end

  def delete_caches_without_priority_term
    if RedmineSla::DbDialect.adapter == :mysql
    execute <<~SQL
      DELETE sla_caches
      FROM sla_caches
      LEFT JOIN issues
        ON issues.id = sla_caches.issue_id
      LEFT JOIN sla_levels
        ON sla_levels.id = sla_caches.sla_level_id
      LEFT JOIN custom_values
        ON (
          custom_values.customized_type = 'Issue'
          AND custom_values.customized_id = issues.id
          AND custom_values.custom_field_id = sla_levels.custom_field_id
        )
      LEFT JOIN sla_level_terms
        ON sla_level_terms.sla_level_id = sla_levels.id
        AND (
          (
            sla_levels.custom_field_id IS NULL
            AND sla_level_terms.sla_priority_id = issues.priority_id
          )
          OR (
            sla_levels.custom_field_id IS NOT NULL
            AND CAST(CAST(sla_level_terms.sla_priority_id AS CHAR) AS BINARY) =
              CAST(custom_values.value AS BINARY)
          )
        )
      WHERE sla_level_terms.id IS NULL
    SQL
    else
    execute <<~SQL
      DELETE FROM sla_caches
      WHERE NOT EXISTS (
        SELECT 1
        FROM issues
        INNER JOIN sla_levels
          ON sla_levels.id = sla_caches.sla_level_id
        INNER JOIN sla_level_terms
          ON sla_level_terms.sla_level_id = sla_levels.id
        LEFT JOIN custom_values
          ON (
            custom_values.customized_type = 'Issue'
            AND custom_values.customized_id = issues.id
            AND custom_values.custom_field_id = sla_levels.custom_field_id
          )
        WHERE issues.id = sla_caches.issue_id
          AND (
            (
              sla_levels.custom_field_id IS NULL
              AND sla_level_terms.sla_priority_id = issues.priority_id
            )
            OR (
              sla_levels.custom_field_id IS NOT NULL
              AND CAST(sla_level_terms.sla_priority_id AS VARCHAR) = custom_values.value
            )
          )
      )
    SQL
    end
  end

  def down
    # Keep the priority-aware function: it remains compatible with 3.5.0, and a
    # rollback should not restore SLA assignments that violate priority terms.
  end

end
