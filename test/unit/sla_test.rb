# frozen_string_literal: true

# File: redmine_sla/test/unit/sla_test.rb
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

class SlaTest < ApplicationSlaUnitsTestCase

  include Redmine::I18n

  def setup
    User.current = nil
    set_language_if_valid 'en'
  end

  def teardown
    User.current = nil
  end

  test "Just initialize" do
    sla = Sla.new
    assert_nil sla.name
  end

  test "should not save Sla without name" do
    sla = Sla.new
    assert_not sla.save, "Saved the Sla without name"
  end

  test "should save Sla with name" do
    sla = Sla.new
    sla.name = "Sla Test !"
    assert sla.save, "Saved the Sla with name"
  end

end