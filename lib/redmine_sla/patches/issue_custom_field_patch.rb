# frozen_string_literal: true

# File: redmine_sla/lib/redmine_sla/patches/issue_custom_field_patch.rb
# Purpose:
#   Extend Redmine's IssueCustomField behavior for SLA-related usage.
#   This patch overrides `to_s` so that SLA custom fields can be rendered
#   consistently (for example in SLA level lists or configuration screens).

# Redmine SLA - Redmine Plugin
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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

require_dependency 'issue_custom_field'

module RedmineSla
  module Patches

    # Patch module for Redmine's IssueCustomField
    module IssueCustomFieldPatch

      # Redefine the string representation to return the field name.
      # This is useful when displaying SLA-related custom fields in lists.
      def to_s
        self.name
      end

      module ClassMethods
      end

      module InstanceMethods
      end

    end
  end
end