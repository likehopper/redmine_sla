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

    BATCH_KEY = :redmine_sla_cache_invalidation_batch

    class << self
      def batch
        if Thread.current[BATCH_KEY]
          yield
        else
          begin
            Thread.current[BATCH_KEY] = []
            result = yield
            SlaCache.invalidate_slas(Thread.current[BATCH_KEY]) if result
            result
          ensure
            Thread.current[BATCH_KEY] = nil
          end
        end
      end

      def invalidate(sla_ids)
        if Thread.current[BATCH_KEY]
          Thread.current[BATCH_KEY].concat(Array(sla_ids).compact)
        else
          SlaCache.invalidate_slas(sla_ids)
        end
      end
    end

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
      RedmineSla::InvalidatesSlaCache.invalidate(@sla_ids_for_cache_invalidation)
    ensure
      @sla_ids_for_cache_invalidation = nil
    end
  end
end
