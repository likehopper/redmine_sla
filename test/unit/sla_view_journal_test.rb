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

require File.expand_path('../../application_sla_units_test_case', __FILE__)

class SlaViewJournalTest < ApplicationSlaUnitsTestCase

  # SlaViewJournal maps to a SQL view (not a regular table).
  # The view is created by the plugin migrations but does NOT exist in the
  # test schema (Rails test:prepare only creates tables from schema.rb).
  # Any AR interaction — including SlaViewJournal.new — triggers a catalog
  # query that raises StatementInvalid when the relation is absent.
  #
  # All tests are therefore skipped when the view is missing.  They will run
  # (and should pass) in an environment where migrations have been applied.

  def view_available?
    ActiveRecord::Base.connection.table_exists?("sla_view_journals")
  rescue
    false
  end

  test "new instance is readonly" do
    skip "sla_view_journals view not available in test schema" unless view_available?
    assert SlaViewJournal.new.readonly?
  end

  test "attempting to save a new instance raises ReadOnlyRecord" do
    skip "sla_view_journals view not available in test schema" unless view_available?
    assert_raises(ActiveRecord::ReadOnlyRecord) { SlaViewJournal.new.save! }
  end

  test "existing records are readonly" do
    skip "sla_view_journals view not available in test schema" unless view_available?
    record = SlaViewJournal.first
    skip "no SlaViewJournal records in test DB" if record.nil?
    assert record.readonly?
  end

  test "attempting to destroy an existing record raises ReadOnlyRecord" do
    skip "sla_view_journals view not available in test schema" unless view_available?
    record = SlaViewJournal.first
    skip "no SlaViewJournal records in test DB" if record.nil?
    assert_raises(ActiveRecord::ReadOnlyRecord) { record.destroy! }
  end

end