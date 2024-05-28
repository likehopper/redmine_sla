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

require_relative "../../test_helper"

class RoutingSlaTypesTest < Redmine::RoutingTest

  def test_slas
    should_route 'GET /sla/types' => 'sla_types#index'
    !should_route 'GET /sla/types.pdf' => 'sla_types#index', :format => 'pdf'
    !should_route 'GET /sla/types.atom' => 'sla_types#index', :format => 'atom'

    should_route 'GET /sla/types/1' => 'sla_types#show', :id => '1'
    !should_route 'GET /sla/types/1.pdf' => 'sla_types#show', :id => '1', :format => 'pdf'
    !should_route 'GET /sla/types/1.atom' => 'sla_types#show', :id => '1', :format => 'atom'

    should_route 'GET /sla/types/new' => 'sla_types#new'
    should_route 'POST /sla/types' => 'sla_types#create'

    should_route 'GET /sla/types/1/edit' => 'sla_types#edit', :id => '1'
    should_route 'PUT /sla/types/1' => 'sla_types#update', :id => '1'
    should_route 'DELETE /sla/types/1' => 'sla_types#destroy', :id => '1'
  end

end