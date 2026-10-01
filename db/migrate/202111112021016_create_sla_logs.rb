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
# File: redmine_sla/db/migrate/202111112021016_create_sla_logs.rb
# Purpose:
#   Create the `sla_logs` table and the PostgreSQL ENUM type `sla_log_level`.
#   This log table stores internal diagnostic and debugging entries produced
#   during SLA calculation or rule evaluation. Each log entry may reference:
#     - a project,
#     - an issue,
#     - an SLA level,
#     - a severity level (ENUM),
#     - and a textual description.
#
#   The migration ensures that the ENUM type is created only once, even if the
#   migration is run multiple times (e.g. when restoring a database).

class CreateSlaLogs < ActiveRecord::Migration[5.2]

  def change

    reversible do |dir|
    
      dir.up do

        # Create ENUM type only if it does not already exist.
        # PostgreSQL-only: MySQL/MariaDB have no standalone named enum type,
        # ENUM(...) is declared directly on the column instead (see below).
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

        # Create diagnostic log table
        create_table :sla_logs do |t|

          # Optional links to project, issue and SLA level.
          # type: :integer on the Redmine-core references below: those core
          # tables predate Rails 5.1's bigint-by-default primary keys and
          # still use `int` ids. PostgreSQL silently allows a bigint foreign
          # key to reference an int primary key, but MySQL/InnoDB rejects the
          # type mismatch outright, so the FK column must match exactly.
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

          # Severity level: the named PostgreSQL ENUM type created above, or
          # (MySQL/MariaDB) an inline ENUM column type with the same values.
          if RedmineSla::DbDialect.adapter == :mysql
            t.column :log_level, "ENUM('log_none','log_error','log_info','log_debug')", null: false
          else
            t.column :log_level, :sla_log_level, null: false
          end

          # Log message
          t.text :description, null: false
        end

        say "Created table sla_logs"

      end

      dir.down do

        # Drop log table first
        drop_table :sla_logs
        say "Dropped table sla_logs"

        # Then drop ENUM (only if exists). PostgreSQL-only: MySQL/MariaDB
        # have no standalone enum type to drop (it lives on the column).
        if RedmineSla::DbDialect.adapter == :postgresql
          execute "DROP TYPE IF EXISTS sla_log_level;"
          say "Dropped enum sla_log_level"
        end
        
      end 

    end

  end

end