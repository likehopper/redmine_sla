# frozen_string_literal: true

# File: redmine_sla/test/integration/slas_test.rb
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

require_relative "../application_sla_integration_test_case"

class SlasTest < ApplicationSlaIntegrationTestCase

  def setup
    User.current = nil
    set_language_if_valid 'en'
  end

  ### As admin #1 ###

  test "should return success on post create then destroy as admin" do
    log_user('admin', 'admin')

    get '/sla/slas/new'
    assert_response :success

    with_settings :default_language => "en" do

      # Add Sla
      sla = new_record(Sla) do
        post('/sla/slas', :params => { sla: { :name => "SLA Test" } } )
      end
      assert_redirected_to :controller => 'slas', :action => 'index'

      # check issue attributes
      id = sla.id
      assert_not_nil Sla.find(id)
      assert_equal 'SLA Test', sla.name

      # Destroy Sla
      delete('/sla/slas', :params => { id: id } )
      assert_redirected_to :controller => 'slas', :action => 'index'
      # check miss sla
      assert_raise ActiveRecord::RecordNotFound do
        assert_nil Sla.find(id)
      end

    end 
    
  end

end