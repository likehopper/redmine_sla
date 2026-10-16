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

# File: redmine_sla/test/unit/migrations/drop_unused_sql_functions_test.rb
# Purpose: unused SQL functions are absent, and dropped from an upgraded
# installation.

require File.expand_path('../../../application_sla_units_test_case', __FILE__)
require Rails.root.join('plugins/redmine_sla/db/migrate/202111112021023_drop_unused_sql_functions')

class DropUnusedSqlFunctionsTest < ApplicationSlaUnitsTestCase
  UNUSED = %w[sla_get_level_overlap sla_explain_level sla_explain_spent].freeze

  test "unused SQL functions are absent while the calculation ones remain" do
    assert_empty existing_functions(UNUSED)
    assert_equal %w[sla_get_level sla_get_spent], existing_functions(%w[sla_get_level sla_get_spent])
  end

  test "upgrade drops unused SQL functions" do
    # MySQL/MariaDB commit implicitly on CREATE FUNCTION, which would end the
    # transaction isolating this test.
    skip "PostgreSQL only" unless RedmineSla::DbDialect.adapter == :postgresql

    connection = ActiveRecord::Base.connection
    connection.execute("CREATE FUNCTION sla_get_level_overlap(INTEGER) RETURNS BOOLEAN LANGUAGE sql AS 'SELECT TRUE'")
    connection.execute("CREATE FUNCTION sla_explain_level(INTEGER) RETURNS BOOLEAN LANGUAGE sql AS 'SELECT TRUE'")
    connection.execute("CREATE FUNCTION sla_explain_spent(INTEGER, INTEGER) RETURNS BOOLEAN LANGUAGE sql AS 'SELECT TRUE'")
    assert_equal UNUSED.sort, existing_functions(UNUSED)

    DropUnusedSqlFunctions.new.migrate(:up)

    assert_empty existing_functions(UNUSED)
  end

  private

  def existing_functions(names)
    connection = ActiveRecord::Base.connection
    list = names.map { |name| connection.quote(name) }.join(', ')
    sql =
      if RedmineSla::DbDialect.adapter == :postgresql
        "SELECT DISTINCT proname FROM pg_proc WHERE proname IN (#{list})"
      else
        "SELECT routine_name FROM information_schema.routines " \
          "WHERE routine_schema = DATABASE() AND routine_name IN (#{list})"
      end
    connection.select_values(sql).map(&:to_s).sort
  end
end
