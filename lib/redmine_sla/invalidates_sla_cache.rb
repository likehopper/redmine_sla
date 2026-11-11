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
# Shares SLA-wide cache invalidation across configuration models.
#
# Redmine SLA - Redmine's Plugin
#
# Including models implement #sla_ids_for_cache_invalidation and resolve only
# which SLAs their changes affect.

module RedmineSla
  module InvalidatesSlaCache
    extend ActiveSupport::Concern

    included do
      before_save :capture_sla_cache_sla_ids_for_save
      after_save :invalidate_sla_cache
      # Capture dependencies before dependent associations remove holiday links.
      before_destroy :capture_sla_cache_sla_ids, prepend: true
      after_destroy :invalidate_sla_cache
    end

    private

    def sla_cache_preserving_change?
      persisted? && changes_to_save.keys == ['description']
    end

    def capture_sla_cache_sla_ids_for_save
      # Also clear dependencies left by an aborted destroy on the same instance.
      @sla_ids_for_cache_invalidation = sla_cache_preserving_change? ? nil : sla_ids_for_cache_invalidation
    end

    def capture_sla_cache_sla_ids
      @sla_ids_for_cache_invalidation = sla_ids_for_cache_invalidation
    end

    def invalidate_sla_cache
      SlaCache.invalidate_slas(@sla_ids_for_cache_invalidation)
    ensure
      @sla_ids_for_cache_invalidation = nil
    end
  end
end
