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
# File: redmine_sla/db/migrate/202111112021019_create_sla_explain_functions.rb
# Purpose:
#   Deploy the read-only diagnostic functions `sla_explain_level` and
#   `sla_explain_spent`, used exclusively by the on-demand "Explain" action
#   (SlaCachesController#explain). They mirror the matching logic of
#   sla_get_level/sla_get_spent but never write to sla_caches/sla_cache_spents
#   — the production calculation functions are not modified by this migration.

class CreateSlaExplainFunctions < ActiveRecord::Migration[5.2]

  def change

    reversible do |dir|

      dir.up do

        # MySQL/MariaDB do not support table-valued functions. Their
        # diagnostic queries are executed through the adapter-neutral Ruby
        # explanation service instead.
        next unless RedmineSla::DbDialect.adapter == :postgresql

        execute File.read(
          File.expand_path('../../sql_functions/sla_explain_level.sql', __FILE__)
        )
        say "Created function sla_explain_level"

        execute File.read(
          File.expand_path('../../sql_functions/sla_explain_spent.sql', __FILE__)
        )
        say "Created function sla_explain_spent"

      end

      dir.down do

        next unless RedmineSla::DbDialect.adapter == :postgresql

        execute "DROP FUNCTION IF EXISTS sla_explain_spent(INTEGER, INTEGER) ;"
        say "Dropped function sla_explain_spent"

        execute "DROP FUNCTION IF EXISTS sla_explain_level(INTEGER) ;"
        say "Dropped function sla_explain_level"

      end

    end

  end

end
