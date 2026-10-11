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
#   Formerly deployed the PostgreSQL-only diagnostic functions
#   `sla_explain_level` and `sla_explain_spent`. The "Explain" action
#   (SlaCachesController#explain) now uses the adapter-neutral
#   RedmineSla::SlaExplanation service, so nothing is created anymore;
#   202111112021022 drops them from existing installations. Rollback still
#   drops them, for installations that have not run 202111112021022.

class CreateSlaExplainFunctions < ActiveRecord::Migration[5.2]

  def change

    reversible do |dir|

      dir.up do
        # Nothing to create anymore (see Purpose above).
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
