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

class RoutingSlasTest < Redmine::RoutingTest

  def test_slas
    should_route 'GET /sla/slas' => 'slas#index'
    !should_route 'GET /sla/slas.pdf' => 'slas#index', :format => 'pdf'
    !should_route 'GET /sla/slas.atom' => 'slas#index', :format => 'atom'

    should_route 'GET /sla/slas/1' => 'slas#show', :id => '1'
    !should_route 'GET /sla/slas/1.pdf' => 'slas#show', :id => '1', :format => 'pdf'
    !should_route 'GET /sla/slas/1.atom' => 'slas#show', :id => '1', :format => 'atom'

    should_route 'GET /sla/slas/new' => 'slas#new'
    should_route 'POST /sla/slas' => 'slas#create'

    should_route 'GET /sla/slas/1/edit' => 'slas#edit', :id => '1'
    should_route 'PUT /sla/slas/1' => 'slas#update', :id => '1'
    should_route 'DELETE /sla/slas/1' => 'slas#destroy', :id => '1'
  end

end