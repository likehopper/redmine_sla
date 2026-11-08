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

# File: redmine_sla/lib/redmine_sla/default_query_retrieval.rb
# Purpose:
#   Select the default saved query of an SLA list before Redmine's
#   retrieve_query runs, like IssuesController does for issues.
#
# Redmine SLA - Redmine's Plugin

module RedmineSla
  module DefaultQueryRetrieval
    private

    # Sets params[:query_id] to the default query of query_class, unless the
    # request already chose a query or filters, or the session holds a query
    # still valid for the current project. Mirrors the private method of
    # Redmine's IssuesController so SLA lists behave like the issue list.
    #
    # use_session is false for exports (CSV), which must not restore or
    # overwrite the query kept for the interactive list.
    def retrieve_default_query(query_class, use_session)
      # An explicit saved query or explicit filters always win.
      return if params[:query_id].present?
      # API clients get the plain list: a default query would change results
      # depending on who calls.
      return if api_request?
      return if params[:set_filter]

      # The sidebar link that deselects the default query sends
      # without_default (Redmine's QueriesHelper): show the unfiltered list
      # instead of selecting that default again.
      if params[:without_default].present?
        params[:set_filter] = 1
        return
      end

      # Keep the query restored from the session (same key as Redmine's
      # QueriesHelper#retrieve_query), as long as it still exists and was
      # chosen in this project; otherwise fall back to the default.
      stored = session[query_class.name.underscore.to_sym]
      if use_session && stored
        query_id, project_id = stored.values_at(:id, :project_id)
        return if query_class.where(id: query_id).exists? && project_id == @project&.id
      end

      # Query.default returns nil for classes without a default (SLA caches,
      # level terms): the list is then left unchanged.
      if (default_query = query_class.default(project: @project))
        params[:query_id] = default_query.id
      end
    end
  end
end
