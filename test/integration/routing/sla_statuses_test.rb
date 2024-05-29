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

class RoutingSlaStatusTest < Redmine::RoutingTest

  def test_slas
    should_route 'GET /sla/statuses' => 'sla_statuses#index'
    !should_route 'GET /sla/statuses.pdf' => 'sla_statuses#index', :format => 'pdf'
    !should_route 'GET /sla/statuses.atom' => 'sla_statuses#index', :format => 'atom'

    should_route 'GET /sla/statuses/1' => 'sla_statuses#show', :id => '1'
    !should_route 'GET /sla/statuses/1.pdf' => 'sla_statuses#show', :id => '1', :format => 'pdf'
    !should_route 'GET /sla/statuses/1.atom' => 'sla_statuses#show', :id => '1', :format => 'atom'

    should_route 'GET /sla/statuses/new' => 'sla_statuses#new'
    should_route 'POST /sla/statuses' => 'sla_statuses#create'

    should_route 'GET /sla/statuses/1/edit' => 'sla_statuses#edit', :id => '1'
    should_route 'PUT /sla/statuses/1' => 'sla_statuses#update', :id => '1'
    should_route 'DELETE /sla/statuses/1' => 'sla_statuses#destroy', :id => '1'
  end

end