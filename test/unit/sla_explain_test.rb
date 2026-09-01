# frozen_string_literal: true

# File: redmine_sla/test/unit/sla_explain_test.rb
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

require File.expand_path('../../application_sla_units_test_case', __FILE__)

# Checks that the read-only sla_explain_level/sla_explain_spent functions
# (used by the "Explain" action) agree with what the production
# sla_get_level/sla_get_spent functions actually computed and cached —
# the explanation must never tell a different story than the real result.
class SlaExplainTest < ApplicationSlaUnitsTestCase

  @@array_fixtures_issues = YAML.load_file(Dir.pwd+"/plugins/redmine_sla/test/config/fixtures.yml")

  test "#SlaExplainTest sla_explain_level selects the same level as the cache" do

    array_fixtures_issues = @@array_fixtures_issues

    array_fixtures_issues.each_key { |array_fixture|

      array_issue = array_fixtures_issues[array_fixture]
      issue_id = array_issue["issue_id"]

      sla_cache = SlaCache.find_by_issue_id(issue_id)

      level_rows = RedmineSla::SlaExplanation.new(Issue.find(issue_id)).levels

      if ( sla_cache.nil? || sla_cache.sla_level_id.nil? )
        assert level_rows.none? { |r| r['selected'] },
          "issue #{issue_id}: expected no selected SLA level, got #{level_rows.inspect}"
      else
        selected = level_rows.find { |r| r['selected'] }
        assert selected, "issue #{issue_id}: sla_explain_level returned no selected row"
        assert_equal sla_cache.sla_level_id, selected['sla_level_id'].to_i,
          "issue #{issue_id}: sla_explain_level selected level #{selected['sla_level_id']} but cache has #{sla_cache.sla_level_id}"
      end
    }

  end

  test "#SlaExplainTest sla_explain_spent totals match the officially computed spent time" do

    array_fixtures_issues = @@array_fixtures_issues

    array_fixtures_issues.each_key { |array_fixture|

      array_issue = array_fixtures_issues[array_fixture]
      issue_id = array_issue["issue_id"]
      issue = Issue.find(issue_id)

      next if ( array_issue["sla_types"].empty? )

      array_issue["sla_types"].each_key { |sla_type_id|

        spent = array_issue["sla_types"][sla_type_id]["spent"].to_i

        sla_term = issue.get_sla_term(sla_type_id)
        next if ( sla_term.nil? )

        sla_spent = issue.get_sla_spent(sla_type_id)
        next if ( sla_spent.nil? )

        spent_rows = RedmineSla::SlaExplanation.new(issue).spent(sla_type_id)

        explained_total = spent_rows.sum { |r| r['minutes_counted'].to_i }

        assert_equal spent, explained_total,
          "issue #{issue_id} type #{sla_type_id}: sla_explain_spent total=#{explained_total} but expected #{spent}"
      }
    }

  end

end
