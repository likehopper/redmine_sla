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

# File: redmine_sla/lib/redmine_sla/invalidates_sla_cache.rb
# Purpose:
#   Shares targeted SLA cache invalidation across cache-dependent models.
#
# Redmine SLA - Redmine's Plugin
#
# Shared Active Record lifecycle for models whose changes invalidate SLA
# calculations. Including models implement #sla_cache_level_ids_for_invalidation
# and remain responsible only for resolving their affected SLA levels.

module RedmineSla
  module InvalidatesSlaCache
    extend ActiveSupport::Concern

    included do
      before_save :capture_sla_cache_level_ids
      after_save :invalidate_sla_cache
      before_destroy :capture_sla_cache_level_ids
      after_destroy :invalidate_sla_cache
    end

    private

    def capture_sla_cache_level_ids
      @sla_cache_level_ids_for_invalidation = sla_cache_level_ids_for_invalidation
    end

    def invalidate_sla_cache
      level_ids = Array(@sla_cache_level_ids_for_invalidation).compact.uniq
      return if level_ids.empty?

      # sla_cache_spents are removed by the database foreign key cascade.
      SlaCache.unscoped.where(sla_level_id: level_ids).delete_all
    ensure
      @sla_cache_level_ids_for_invalidation = nil
    end
  end
end
