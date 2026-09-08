# frozen_string_literal: true

# File: redmine_sla/test/integration/routing/sla_project_catalogs_test.rb
# Redmine SLA - Redmine's Plugin
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.

require_relative "../../application_sla_routing_test_case"

class RoutingSlaProjectCatalogsTest < ApplicationSlaRoutingTestCase

  def test_project_sla_levels
    should_route 'GET /projects/project-sla-tests-tma/sla/levels' =>
      'sla_levels#index', project_id: 'project-sla-tests-tma'
    should_route 'GET /projects/project-sla-tests-tma/sla/levels/1' =>
      'sla_levels#show', project_id: 'project-sla-tests-tma', id: '1'
  end

  def test_project_sla_calendars
    should_route 'GET /projects/project-sla-tests-tma/sla/calendars' =>
      'sla_calendars#index', project_id: 'project-sla-tests-tma'
    should_route 'GET /projects/project-sla-tests-tma/sla/calendars/1' =>
      'sla_calendars#show', project_id: 'project-sla-tests-tma', id: '1'
  end

end
