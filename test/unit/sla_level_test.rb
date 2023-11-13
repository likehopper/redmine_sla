# frozen_string_literal: true

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

require File.expand_path('../../test_helper', __FILE__)

class SlaLevelTest < ActiveSupport::TestCase

  fixtures \
    :users,
    :email_addresses,
    :roles,
    :enumerations,
    :issue_statuses,
    :trackers,
    :workflows,
    :slas,
    :sla_calendars,
    :sla_holidays,
    :sla_calendar_holidays,
    :sla_schedules,
    :sla_types,
    :sla_levels,
    :sla_level_terms,
    :sla_statuses,
    :projects,
    :members,
    :member_roles,
    :projects_trackers,
    :sla_project_trackers,
    :enabled_modules,
    :issues,
    :journals,
    :journal_details

  setup do
  end

    # Load yml config
    @@array_fixtures_issues = YAML.load_file(Dir.pwd+"/plugins/redmine_sla/test/config/fixtures.yml")


  test "#SlaLevelTest SLA for issues from fixtures" do

    array_fixtures_issues = @@array_fixtures_issues
    
    array_fixtures_issues.each_key { |array_fixture|

      array_issue = array_fixtures_issues[array_fixture]
      issue_id = array_issue["issue_id"]
      @issue = Issue.find(issue_id) ;

      # puts "- process issue_id = #{issue_id}"

      if ( array_issue["sla_types"].empty? )
        # puts "- - process NO SLA for issue_id = #{issue_id}"
      else 

        array_issue["sla_types"].each_key { |sla_type_id|

          # puts "- - process sla_type_id = #{sla_type_id}"

          spent = array_issue["sla_types"][sla_type_id]["spent"].to_i
          term = array_issue["sla_types"][sla_type_id]["term"].to_i

          sla_type_name = SlaType.find(sla_type_id).name

          if ( sla_type_name.nil? )
            # puts "- - - sla_type_id = #{sla_type_id} NOT FOUND"
            assert false
          end

          # puts "- - - > expected > spent = #{spent} for term = #{term}"

          sla_cache = SlaCache.find_or_new(issue_id)
          
          sla_level_term = SlaLevelTerm.find_by_level_type(sla_cache.sla_level_id,sla_type_id,@issue.priority_id)
          if ( sla_level_term.nil? )
            next
          end          
          sla_type_term_issue = sla_level_term[:term]

          sla_cache_spent = SlaCacheSpent.find_or_new(sla_cache.id,sla_type_id)
          sla_type_spent_issue = sla_cache_spent[:spent]
        
          # puts "- - - > found > spent = #{sla_type_spent_issue} for term = #{sla_type_term_issue}"

          if ( sla_type_term_issue != term )
            # puts "- - - => DELAY #{sla_type_name} FAILED ==>> expected #{term} vs #{sla_type_term_issue} found"
            assert false
          end

          if ( sla_type_spent_issue != spent )
            # puts "- - - => SPENT #{sla_type_name} FAILED ==>> expected #{spent} vs #{sla_type_spent_issue} found"
            assert false
          end

        }
      end
    }

    assert true

  end
  
  test "#SlaLevelTest TMA/GTR" do
    assert SlaCache.count(:all).zero?
  end

  def test_truth
    assert true
  end

end