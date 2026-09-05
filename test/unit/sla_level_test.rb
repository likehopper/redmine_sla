# frozen_string_literal: true

# File: redmine_sla/test/unit/sla_level_test.rb
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

class SlaLevelTest < ApplicationSlaUnitsTestCase

  setup do
  end

  # Load yml config
  @@array_fixtures_issues = YAML.load_file(Dir.pwd+"/plugins/redmine_sla/test/config/fixtures.yml")

  test "visible? is scoped to projects where the Resolver has view_sla" do
    resolver = User.find(3)

    assert SlaLevel.find(1).visible?(resolver)
    assert_not SlaLevel.find(3).visible?(resolver)
  end


  test "#SlaLevelTest SLA for issues from fixtures" do

    array_fixtures_issues = @@array_fixtures_issues
    
    array_fixtures_issues.each_key { |array_fixture|

      array_issue = array_fixtures_issues[array_fixture]
      issue_id = array_issue["issue_id"]
      issue = Issue.find(issue_id) ;

      puts "- process issue_id = #{issue_id}"

      if ( array_issue["sla_types"].empty? )
        # puts "- - process NO SLA for issue_id = #{issue_id}"
      else 

        array_issue["sla_types"].each_key { |sla_type_id|

          # puts "- - process sla_type_id = #{sla_type_id}"

          spent = array_issue["sla_types"][sla_type_id]["spent"].to_i
          term = array_issue["sla_types"][sla_type_id]["term"].to_i

          sla_type_name = SlaType.find(sla_type_id).name

          assert_not_nil sla_type_name, "SLA type #{sla_type_id} was not found"

          sla_cache = SlaCache.find_by_issue_id(issue_id)
          
          sla_term = issue.get_sla_term(sla_type_id)
          next if ( sla_term.nil? )

          sla_spent = issue.get_sla_spent(sla_type_id)
          next if ( sla_spent.nil? )

          # puts "- - - > found > spent = #{sla_type_spent_issue} for term = #{sla_type_term_issue}"

          assert_equal term, sla_term,
            "Unexpected #{sla_type_name} term for issue #{issue_id}"
          assert_equal spent, sla_spent,
            "Unexpected #{sla_type_name} spent time for issue #{issue_id}"

        }
      end
    }

    assert true

  end

end
