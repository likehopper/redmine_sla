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

module SlaCachesHelper

  def _sla_caches_path(project, issue, *args)
    if project
      project_sla_caches_path(project, *args)
    else
      sla_caches_path(*args)
    end
  end

  def render_api_includes(sla_cache, api)
    api.array :sla_cache_spents do
      sla_cache.sla_cache_spents.each do |sla_cache_spent|
        api.sla_cache_spent(
          :id => sla_cache_spent.id,
          :sla_type => sla_cache_spent.sla_type,
          :spent => sla_cache_spent.spent
        )
      end
    end if include_in_api_response?('sla_cache_spents')
  end

end