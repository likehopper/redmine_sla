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

# File: redmine_sla/test/unit/migrations/gate_sla_get_level_on_project_module_test.rb
# Purpose: the upgrade purges the cache left by projects whose SLA module was
# disabled before it, and keeps the cache of projects still using the module.

require File.expand_path('../../../application_sla_units_test_case', __FILE__)
require Rails.root.join('plugins/redmine_sla/db/migrate/202111112021021_gate_sla_get_level_on_project_module')

class GateSlaGetLevelOnProjectModuleTest < ApplicationSlaUnitsTestCase
  test "upgrade purges caches of projects without the SLA module only" do
    # The migration redeploys sla_get_level: MySQL/MariaDB commit implicitly on
    # DROP/CREATE FUNCTION, which would end the transaction isolating this test,
    # while PostgreSQL rolls the redeployment back with it.
    skip "PostgreSQL only" unless RedmineSla::DbDialect.adapter == :postgresql

    project_ids = SlaCache.distinct.order(:project_id).pluck(:project_id)
    assert_operator project_ids.size, :>=, 2, "fixtures must cache issues of two projects"
    disabled_project_id, enabled_project_id = project_ids
    disabled_cache_ids = SlaCache.where(project_id: disabled_project_id).pluck(:id)
    enabled_cache_ids = SlaCache.where(project_id: enabled_project_id).pluck(:id)
    assert EnabledModule.exists?(project_id: enabled_project_id, name: 'sla')

    # Bypass the module callbacks to reproduce a module disabled before the upgrade.
    assert_equal 1, EnabledModule.where(project_id: disabled_project_id, name: 'sla').delete_all
    # Only the migration may purge them, not a module callback.
    assert_equal disabled_cache_ids.sort, SlaCache.unscoped.where(id: disabled_cache_ids).pluck(:id).sort

    GateSlaGetLevelOnProjectModule.new.migrate(:up)

    assert_not SlaCache.unscoped.where(id: disabled_cache_ids).exists?
    assert_equal enabled_cache_ids.sort, SlaCache.unscoped.where(id: enabled_cache_ids).pluck(:id).sort
  end
end
