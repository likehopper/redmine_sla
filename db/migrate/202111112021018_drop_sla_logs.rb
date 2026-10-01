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
# File: redmine_sla/db/migrate/202111112021018_drop_sla_logs.rb
# Purpose:
#   Remove the `sla_logs` table and the PostgreSQL ENUM type `sla_log_level`
#   introduced by migration 202111112021016. This internal logging feature
#   was never implemented (broken model, no code ever wrote to this table)
#   and has been abandoned in favor of an on-demand "Explain" diagnostic
#   tool that queries the SLA calculation live, without persisting anything.

class DropSlaLogs < ActiveRecord::Migration[5.2]

  def change

    reversible do |dir|

      dir.up do

        drop_table :sla_logs
        say "Dropped table sla_logs"

        if RedmineSla::DbDialect.adapter == :postgresql
          execute "DROP TYPE IF EXISTS sla_log_level;"
          say "Dropped enum sla_log_level"
        end

      end

      dir.down do

        if RedmineSla::DbDialect.adapter == :postgresql
          execute <<~SQL
            DO $$
            BEGIN
              IF NOT EXISTS (
                SELECT 1 FROM pg_type WHERE typname = 'sla_log_level'
              ) THEN
                CREATE TYPE sla_log_level AS ENUM
                  ('log_none', 'log_error', 'log_info', 'log_debug');
              END IF;
            END;
            $$;
          SQL
          say "Created enum sla_log_level"
        end

        create_table :sla_logs do |t|

          t.belongs_to :project,
                       null: true,
                       type: :integer,
                       foreign_key: {
                         name: 'sla_logs_projects_fkey',
                         on_delete: :cascade
                       }

          t.belongs_to :issue,
                       null: true,
                       type: :integer,
                       foreign_key: {
                         name: 'sla_logs_issues_fkey',
                         on_delete: :cascade
                       }

          t.belongs_to :sla_level,
                       null: true,
                       foreign_key: {
                         name: 'sla_logs_sla_levels_fkey',
                         on_delete: :cascade
                       }

          if RedmineSla::DbDialect.adapter == :mysql
            t.column :log_level, "ENUM('log_none','log_error','log_info','log_debug')", null: false
          else
            t.column :log_level, :sla_log_level, null: false
          end

          t.text :description, null: false
        end

        say "Created table sla_logs"

      end

    end

  end

end
