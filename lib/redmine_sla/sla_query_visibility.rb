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

# File: redmine_sla/lib/redmine_sla/sla_query_visibility.rb
# Purpose:
#   Hide SLA values of query rows whose project does not grant view_sla.
#
# An issue or time entry list can include rows of subprojects where the user
# lacks view_sla, even when the queried project grants it. SLA values, sorting,
# grouping and filters therefore check the permission on each row's project.

require_dependency 'query'

module RedmineSla
  module SlaQueryVisibility
    def self.visible?(project, user = User.current)
      project.present? && user.allowed_to?(:view_sla, project)
    end

    # Projects whose SLA data the user may see, as a subquery for SQL joins.
    def self.visible_project_ids_sql(user = User.current)
      "SELECT projects.id FROM projects WHERE #{Project.allowed_to_condition(user, :view_sla)}"
    end
  end

  # Query column whose value (HTML, CSV, PDF, group) is hidden on rows of
  # projects without view_sla.
  class SlaQueryColumn < QueryColumn
    def value(object)
      super if SlaQueryVisibility.visible?(object.project)
    end

    def value_object(object)
      super if SlaQueryVisibility.visible?(object.project)
    end
  end
end
