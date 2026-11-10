# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

require_dependency 'issue_priority'

module RedmineSla
  module Patches
    module IssuePriorityPatch
      extend ActiveSupport::Concern
      include RedmineSla::InvalidatesSlaCache

      private

      def sla_cache_preserving_change?
        persisted?
      end

      def sla_ids_for_cache_invalidation
        terms = SlaLevelTerm.unscoped.where(sla_priority_id: id).select(:sla_level_id)
        SlaLevel.unscoped.where(custom_field_id: nil, id: terms).distinct.pluck(:sla_id)
      end
    end
  end
end
