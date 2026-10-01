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
# File: redmine_sla/db/migrate/202111112021011_create_sla_get_date.rb
# Purpose:
#   Deploy the `sla_get_date` function, which normalizes timestamps according
#   to the configured SLA timezone and truncates them to the minute. The
#   function is stored per-dialect under `db/sql_functions/<adapter>/sla_get_date.sql`
#   and loaded using a reversible migration so it can be cleanly removed on rollback.

class CreateSlaGetDate < ActiveRecord::Migration[5.2]

  def change

    reversible do |dir|

      dir.up do
        # MySQL has no CREATE OR REPLACE FUNCTION (unlike PostgreSQL, whose
        # file already self-contains an equivalent DROP), and Rails' mysql2
        # driver doesn't support multiple statements in a single execute call,
        # so the drop is issued separately here.
        execute "DROP FUNCTION IF EXISTS sla_get_date ;" if RedmineSla::DbDialect.adapter == :mysql

        # Execute the SQL function definition from the dialect-specific SQL file
        execute RedmineSla::DbDialect.function_sql('sla_get_date')
        say "Created function sla_get_date"
      end

      dir.down do
        # Remove the function if the migration is rolled back
        if RedmineSla::DbDialect.adapter == :mysql
          execute "DROP FUNCTION IF EXISTS sla_get_date ;"
        else
          execute "DROP FUNCTION IF EXISTS public.sla_get_date CASCADE ;"
        end
        say "Dropped function sla_get_date"
      end

    end

  end

end