# frozen_string_literal: true

# File: redmine_sla/test/documentation/modules/08_custom_fields_module.rb
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

require 'yaml'

module CustomFieldsDocumentationTest

  # Documentation test: Custom fields (Issue custom fields)
  #
  # This test is data-driven: it loads the configuration from a YAML file and
  # loops through each custom field definition to create/update it, inject
  # possible values (when the UI is too slow/fragile), set the default value,
  # and take screenshots.
  def test_08_custom_field
    id = 8

    log_user('admin', 'admin')

    fixture!('custom_fields').each.with_index(1) do |cf, idx|
      create_or_update_custom_field_from_config!(cf: cf, id: id, idx: idx)
    end

    # Final list screenshot (Issue custom fields tab)
    visit '/custom_fields?tab=IssueCustomField'
    take_doc_screenshot(format('%02d-02-custom_fields-list.png', id))
  end

  private

  # Creates the custom field through the UI, then injects values and default value.
  def create_or_update_custom_field_from_config!(cf:, id:, idx:)
    type = (cf['type'] || 'issue').to_s

    unless type == 'issue'
      raise ArgumentError, "Unsupported custom field type '#{type}' in 08_custom_fields_module"
    end

    # -----------------------------
    # 1) UI: Create the custom field
    # -----------------------------
    visit '/custom_fields/new?type=IssueCustomField'

    # Field format (label must match the UI translation in your test environment)
    select field_format_label(cf.fetch('field_format')), from: 'custom_field_field_format'

    fill_in 'custom_field_name', with: cf.fetch('name')
    fill_in 'custom_field_description', with: (cf['description'] || '')

    # Multiple values
    if cf['multiple']
      check 'custom_field_multiple'
    else
      uncheck 'custom_field_multiple' rescue nil
    end

    # Required
    if cf['required']
      check 'custom_field_is_required'
    else
      uncheck 'custom_field_is_required' rescue nil
    end

    # Used as a filter
    if cf['is_filter']
      check 'custom_field_is_filter'
    else
      uncheck 'custom_field_is_filter' rescue nil
    end

    # Visible: for now we support only "all" (= any users)
    case (cf['visible'] || 'all').to_s
    when 'all'
      choose 'custom_field_visible_on'
    else
      raise ArgumentError, "Unsupported visible value '#{cf['visible']}' (supported: all)"
    end

    # Display (drop-down list / checkboxes) - only relevant for list-like formats.
    if cf['display']
      begin
        select display_label(cf['display']), from: 'custom_field_edit_tag_style'
      rescue Capybara::ElementNotFound
        # Some formats do not expose Display; ignore.
      end
    end

    # Trackers: uncheck all first, then check only what is requested.
    requested_trackers = Array(cf['trackers']).map(&:to_s)
    all('input[type="checkbox"][name="custom_field[tracker_ids][]"]').each do |checkbox|
      uncheck checkbox[:id] rescue nil
    end
    requested_trackers.each do |tracker_label|
      check tracker_label
    end

    # Projects: disable "For all projects" and check the selected ones.
    # If projects is empty => no project association.
    begin
      uncheck 'custom_field_is_for_all'
    rescue StandardError
      # Not always present depending on Redmine version/config.
    end

    # Array(cf['projects']).map(&:to_s).each do |project_identifier|
    #   check project_identifier
    # end
    projects = Array(cf['projects'])

    if projects.empty?
      check('custom_field_is_for_all') rescue nil
    else
      uncheck('custom_field_is_for_all') rescue nil

      projects.each do |project_identifier|
        project =
          Project.find_by(identifier: project_identifier)
        raise "Project not found (identifier or name): #{project_ref}" unless project

        check project.name
      end
    end

    take_doc_screenshot(format('%02d-01-%02d-custom_field-new.png', id, idx))
    click_button 'Create'

    # -----------------------------
    # 2) Model: Inject possible values (more reliable than UI)
    # -----------------------------
    custom_field = CustomField.find_by!(name: cf.fetch('name'))

    # Ensure non-UI attributes are aligned with the config (even if the UI does not expose them).
    # Some of these attributes may not exist depending on Redmine version; ignore gracefully.
    begin
      custom_field.searchable = !!cf['searchable'] if custom_field.respond_to?(:searchable=)
      custom_field.editable   = !!cf['editable'] if custom_field.respond_to?(:editable=)
      custom_field.save! if custom_field.changed?
    rescue StandardError
      # Ignore if not supported.
    end

    inject_values!(custom_field, cf['values'])

    # Values screenshot (where available)
    begin
      visit "/custom_fields/#{custom_field.id}/enumerations"
      take_doc_screenshot(format('%02d-02-%02d-custom_field-values.png', id, idx))
    rescue StandardError
      # Some formats do not have enumerations page.
    end

    # -----------------------------
    # 3) UI: Set default value
    # -----------------------------
    if cf['default_value']
      visit "/custom_fields/#{custom_field.id}/edit"

      # Wait for the option to appear (values are injected just above)
      assert_selector '#custom_field_default_value option', text: cf['default_value'].to_s, wait: 10
      select cf['default_value'].to_s, from: 'custom_field_default_value'

      click_button 'Save'
      assert_text l(:notice_successful_update)

      take_doc_screenshot(format('%02d-03-%02d-custom_field-final.png', id, idx))
    end
  end

  # Injects values using the model layer.
  #
  # - For key/value list: values are expected as array of hashes {label, active}
  #   and are stored as custom_field.enumerations.
  # - For simple list: values are expected as array of strings and are stored in
  #   custom_field.possible_values.
  def inject_values!(custom_field, values)
    values = Array(values)
    return if values.empty?

    if values.first.is_a?(Hash)
      # Key/value list (CustomFieldEnumeration)
      custom_field.enumerations.delete_all

      values.each_with_index do |v, position|
        label = v.fetch('label').to_s
        active = !!v.fetch('active', true)

        custom_field.enumerations.create!(
          name: label,
          active: active,
          position: position + 1
        )
      end
    else
      # Simple list
      custom_field.possible_values = values.map(&:to_s)
      custom_field.save!
    end
  end

  def field_format_label(field_format)
    # The select expects UI labels.
    # Adjust here if you run tests with different locales.
    case field_format.to_s
    when 'key_value_list'
      'Key/value list'
    when 'list'
      'List'
    else
      # If you add more formats later, map them here.
      field_format.to_s
    end
  end

  def display_label(display)
    case display.to_s
    when 'drop_down_list', 'dropdown', 'drop-down-list'
      'drop-down list'
    when 'check_boxes', 'checkboxes'
      'checkboxes'
    else
      display.to_s
    end
  end
end