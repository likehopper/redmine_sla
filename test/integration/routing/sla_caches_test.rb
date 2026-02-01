# frozen_string_literal: true

# File: redmine_sla/test/integration/routing/sla_caches_test.rb
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

# require_relative "../../test_helper"
require_relative "../../application_sla_routing_test_case"

class RoutingSlaCachesTest < ApplicationSlaRoutingTestCase

  def test_sla_caches
    should_route 'GET /sla/caches' => 'sla_caches#index'
    !should_route 'GET /sla/caches.pdf' => 'sla_caches#index', :format => 'pdf'
    !should_route 'GET /sla/caches.atom' => 'sla_caches#index', :format => 'atom'

    should_route 'GET /sla/caches/1' => 'sla_caches#show', :id => '1'
    !should_route 'GET /sla/caches/1.pdf' => 'sla_caches#show', :id => '1', :format => 'pdf'
    !should_route 'GET /sla/caches/1.atom' => 'sla_caches#show', :id => '1', :format => 'atom'

    # TODO : test miss routes
    # !should_route 'GET /sla/caches/new' => 'sla_caches#new'
    # !should_route 'POST /sla/caches' => 'sla_caches#create'

    # !should_route 'GET /sla/caches/1/edit' => 'sla_caches#edit', :id => '1'
    # !should_route 'PUT /sla/caches/1' => 'sla_caches#update', :id => '1'
    should_route 'DELETE /sla/caches/1' => 'sla_caches#destroy', :id => '1'

    should_route 'GET /sla/caches/1/refresh' => 'sla_caches#refresh', :id => '1'
    should_route 'GET /sla/caches/refresh' => 'sla_caches#refresh'
    should_route 'GET /sla/caches/purge' => 'sla_caches#purge'
  end

end