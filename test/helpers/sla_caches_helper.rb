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

# require File.expand_path('../../../application_system_test_case', __FILE__)

# class SlasSystemTest < ApplicationSystemTestCase
module SlaCachesHelperTest

  def renew_issue(issue_id)
    issue = Issue.find(issue_id)
    SlaType.all.each { |sla_type|
      issue.get_sla_spent(sla_type.id)
    }
  end
end