# frozen_string_literal: true

# File: redmine_sla/test/documentation/modules/07_projects_module.rb
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

module ProjectsDocumentationTest
  def test_07_project
    id = 07

    log_user('admin', 'admin')

    fixture!('projects').each.with_index(1) do |project, idx|

      # Resolve names -> records
      project_name        = project.fetch('name')
      project_identifier  = project.fetch('identifier')
      project_description = project.fetch('description', '')
      project_public      = project.fetch('public',false)
      project_sla         = project.fetch('sla',false)

      # Open and fill out the form
      visit '/projects/new'
      fill_in 'project_name',        with: project_name
      fill_in 'project_identifier',  with: project_identifier
      fill_in 'project_description', with: project_description

      # Public / private
      if project_public
        check 'project_is_public'
      else
        uncheck 'project_is_public'
      end

      # Modules (SLA + issue tracking)
      if project_sla
        check 'project_enabled_module_names_sla'
      else
        uncheck 'project_enabled_module_names_sla'
      end

      check 'project_enabled_module_names_issue_tracking'

      # Take the photo and submit the form
      take_doc_screenshot(format("%02d-01-%02d-project-new.png", id, idx))
      click_button 'Create'

      assert_text l(:notice_successful_create)

      # Search for the record
      project = Project.find_by!(identifier: project_identifier)

      # Validation and screenshot
      assert_equal project_name, project.name
      take_doc_screenshot(format("%02d-02-%02d-project-show.png", id, idx))
      
    end
  end
end