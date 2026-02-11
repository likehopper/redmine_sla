# frozen_string_literal: true

# File: plugins/redmine_sla/test/documentation/modules/11_project_settings_module.rb
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

module ProjectSettingsDocumentationTest
  # Configure project settings for documentation:
  # - Enable / disable trackers (Project settings > Issue tracking)
  # - Optionally add members (Project settings > Members)
  # - Configure SLA tracker mapping (Project settings > SLA)
  #
  # Expected YAML fixture structure (project_settings.yml):
  #
  # project_settings:
  #   - project: "project-identifier"
  #     issue_trackers:
  #       - "Bug"
  #       - "Feature"
  #     members:
  #       - principal: "Redmine Manager"
  #         roles:
  #           - "Manager"
  #     sla_trackers:
  #       "Bug": "SLA - Bug HO"
  #       "Feature": "SLA - Feature HO"
  #
  def test_11_project_settings
    id = 11

    log_user('admin', 'admin')

    # Read fixture (array of project settings). If empty, there is nothing to document here.
    project_settings = Array(fixture!('project_settings'))
    return if project_settings.empty?

    project_settings.each.with_index(1) do |project_config, idx|
      project_identifier = project_config.fetch('project')
      project = Project.find_by!(identifier: project_identifier)

      # -----------------------------
      # 1) Issue tracking settings
      # -----------------------------
      visit "/projects/#{project.identifier}/settings/issues"
      take_doc_screenshot(format('%02d-01-%02d-project-settings-issues.png', id, idx))

      # Trackers that should be enabled for this project (matching by tracker name displayed in UI).
      enabled_tracker_names = Array(project_config['issue_trackers']).map(&:to_s)

      # Trackers from DB, indexed by id (string, because HTML values are strings)
      trackers_by_id = Tracker.all.index_by { |t| t.id.to_s }

      # Loop over ALL tracker checkboxes in UI and set them according to enabled_tracker_names
      all("input[type='checkbox'][name='project[tracker_ids][]']", visible: :all).each do |checkbox|
        tracker = trackers_by_id[checkbox.value]
        next unless tracker

        checkbox.set(enabled_tracker_names.include?(tracker.name))
      end

      click_button l(:button_save)
      take_doc_screenshot(format('%02d-02a-%02d-project-settings-issues-saved.png', id, idx))

      # -----------------------------
      # 1bis) Members settings (optional)
      # -----------------------------
      visit "/projects/#{project.identifier}/settings/members"
      take_doc_screenshot(format('%02d-02b-%02d-project-settings-members.png', id, idx))

      members_config = Array(project_config['members'])
      if members_config.any?
        members_config.each.with_index(1) do |member_config, member_idx|
          # Open "New member" form (label may vary depending on locale/version)
          begin
            click_link 'New member'
          rescue StandardError
            click_link l(:label_member_new)
          end

          # Page: /projects/:id/memberships/new
          principal_name = member_config.fetch('principal')
          role_names     = Array(member_config['roles']).map(&:to_s)

          # Select principal (user/group). Depending on Redmine/driver, it can be inside an AJAX modal.
          begin
            within('#ajax-modal', wait: 5) do
              check principal_name
            end
          rescue Capybara::ElementNotFound
            begin
              check principal_name
            rescue Capybara::ElementNotFound
              raise Capybara::ElementNotFound,
                    "Unable to check principal='#{principal_name}' on memberships/new for project '#{project.identifier}'"
            end
          end

          # Check roles
          role_names.each do |role_name|
            begin
              check role_name
            rescue Capybara::ElementNotFound
              raise Capybara::ElementNotFound,
                    "Unable to check role='#{role_name}' for principal='#{principal_name}' on project '#{project.identifier}'"
            end
          end

          take_doc_screenshot(format('%02d-02c-%02d-%02d-project-settings-members-new.png', id, idx, member_idx))

          # Submit
          begin
            click_button 'Add'
          rescue StandardError
            click_button l(:button_add)
          end
        end

        # Back to members list after additions
        visit "/projects/#{project.identifier}/settings/members"
        take_doc_screenshot(format('%02d-02d-%02d-project-settings-members-list.png', id, idx))
      end

      # -----------------------------
      # 2) SLA Project settings
      # -----------------------------
      visit "/projects/#{project.identifier}/settings/sla"
      take_doc_screenshot(format('%02d-03-%02d-project-settings-sla.png', id, idx))

      # Hash mapping: "Tracker label/name" => "SLA name"
      sla_tracker_mappings = project_config['sla_trackers'] || {}

      sla_tracker_mappings.each.with_index(1) do |(tracker_label, sla_name), mapping_idx|
        # Open "New SLA project's trackers" form
        click_link "New SLA project's trackers"

        # Now on /projects/:id/settings/sla/new
        select tracker_label.to_s, from: 'sla_project_tracker_tracker_id'
        select sla_name.to_s, from: 'sla_project_tracker_sla_id'

        take_doc_screenshot(format('%02d-04-%02d-%02d-project-settings-sla-new.png', id, idx, mapping_idx))

        click_button 'Create'
        # After creation, Redmine typically redirects back to the list.
      end

      take_doc_screenshot(format('%02d-05-%02d-project-settings-sla-list.png', id, idx))
      
    end
  end
end