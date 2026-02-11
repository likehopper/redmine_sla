# frozen_string_literal: true

# File: redmine_sla/test/documentation/modules/09_sla_levels_module.rb
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

module SlaLevelsDocumentationTest

  def test_09_sla_level
    id = 9

    sla_levels = fixture!('sla_levels')

    log_user('admin', 'admin') if sla_levels.any?

    sla_levels.each.with_index(1) do |sla_level, idx|
      sla_level_name                 = sla_level.fetch('name')
      sla_name                       = sla_level.fetch('sla')
      sla_calendar_name              = sla_level.fetch('sla_calendar')
      sla_priority_custom_field_name = sla_level.fetch('sla_priority_custom_field',nil)

      visit '/sla/levels/new'
      fill_in 'sla_level_name', with: sla_level_name

      # Resolve names -> records
      sla = Sla.find_by!(name: sla_name)
      sla_calendar = SlaCalendar.find_by!(name: sla_calendar_name)

      # On cherche le Custom Field par son nom (SlaPriorityScf)
      sla_priority_custom_field = CustomField.find_by(name: sla_priority_custom_field_name)

      # Select by id
      find('#sla_level_sla_id').find("option[value='#{sla.id}']").select_option
      find('#sla_level_sla_calendar_id').find("option[value='#{sla_calendar.id}']").select_option

      # 3. Sélection du Custom Field (si défini dans @sla_levels)
      if sla_priority_custom_field
        find('#sla_level_custom_field_id').find("option[value='#{sla_priority_custom_field.id}']").select_option
      end

      take_doc_screenshot(format("%02d-01-%02d-01-sla_level-new.png", id, idx))
      click_button l("sla_label.sla_level.new")

      sla_level = SlaLevel.find_by!(name: sla_level_name)
      
      assert_text(l('sla_label.sla_level.notice_successful_create', id: "##{sla_level.id}"))
      take_doc_screenshot(format("%02d-01-%02d-02-sla_leel-created.png", id, idx))
      
    end

    # take_doc_screenshot(format("%02d-02-sla_level-list.png", id)) if sla_levels.any?

  end
end