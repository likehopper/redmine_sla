# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

require_dependency 'issue_priority'

module RedmineSla
  module Patches
    # Redmine reassigns issues with update_all, which bypasses Issue callbacks.
    module IssuePriorityReassignmentPatch
      def transfer_relations(to)
        issue_ids = issues.pluck(:id)
        super.tap { SlaCache.invalidate_issues(issue_ids) }
      end
    end
  end
end
