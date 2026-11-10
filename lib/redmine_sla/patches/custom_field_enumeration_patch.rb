# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

require_dependency 'custom_field_enumeration'

module RedmineSla
  module Patches
    module CustomFieldEnumerationPatch
      extend ActiveSupport::Concern
      include RedmineSla::InvalidatesSlaCache

      private

      def sla_ids_for_cache_invalidation
        # Redmine can reassign custom values with update_all on deletion.
        # Invalidate every level using the field, including the previous field.
        field_ids = [custom_field_id, attribute_in_database('custom_field_id')].compact.uniq
        SlaLevel.unscoped.where(custom_field_id: field_ids).distinct.pluck(:sla_id)
      end
    end
  end
end
