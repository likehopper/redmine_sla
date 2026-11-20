# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

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

# Checks that the read-only RedmineSla::SlaExplanation service (used by the
# "Explain" action) agrees with what the production sla_get_level/
# sla_get_spent functions actually computed and cached —
# the explanation must never tell a different story than the real result.
class SlaExplainTest < ApplicationSlaUnitsTestCase

  @@array_fixtures_issues = YAML.load_file(Dir.pwd+"/plugins/redmine_sla/test/config/fixtures.yml")

  test "#SlaExplainTest explained levels select the same level as the cache" do

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
        assert selected, "issue #{issue_id}: explanation returned no selected level"
        assert_equal sla_cache.sla_level_id, selected['sla_level_id'].to_i,
          "issue #{issue_id}: explanation selected level #{selected['sla_level_id']} but cache has #{sla_cache.sla_level_id}"
      end
    }

  end

  test "#SlaExplainTest explained spent totals match the officially computed spent time" do

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
          "issue #{issue_id} type #{sla_type_id}: explained total=#{explained_total} but expected #{spent}"
      }
    }

  end

  # Schedules with match=false (outside business hours) still let time run in
  # sla_get_spent. The explanation must count the day and say so, not report
  # it as a day without schedule (EXAMPLE-05, weekend of issue_past_4).
  test "#SlaExplainTest a day outside business hours counts minutes and is reported as such" do

    gtr = 2 # counts New and Assigned
    saturday = Date.new(2021, 11, 6)
    project = Project.find_by!(identifier: 'project-sla-tests-tma')
    issue = Issue.find_by!(project: project, subject: 'Bug with a weekend')
    spent_without_weekend = issue.get_sla_spent(gtr)
    saturday_row = RedmineSla::SlaExplanation.new(issue).spent(gtr).find { |row| row['day'] == saturday }
    assert_not saturday_row['has_schedule']
    assert_equal 0, saturday_row['minutes_counted']

    # Time runs on Saturday, but no SLA can start there.
    issue.get_sla_level.sla_calendar.sla_schedules.create!(dow: 6, start_time: '00:00', end_time: '23:59', match: false)

    issue = Issue.find(issue.id)
    spent = issue.get_sla_spent(gtr)
    rows = RedmineSla::SlaExplanation.new(issue).spent(gtr)
    saturday_row = rows.find { |row| row['day'] == saturday }

    assert_equal spent_without_weekend + 1440, spent
    assert_equal spent, rows.sum { |row| row['minutes_counted'] }
    assert saturday_row['has_schedule']
    assert saturday_row['outside_business_hours']
    assert_equal 1440, saturday_row['minutes_counted']
    assert rows.reject { |row| row['day'] == saturday }.none? { |row| row['outside_business_hours'] }

  end

end
