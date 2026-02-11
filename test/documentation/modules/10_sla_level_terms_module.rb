# frozen_string_literal: true

# File: redmine_sla/test/documentation/modules/10_sla_level_terms_module.rb
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

module SlaLevelTermsDocumentationTest

  def test_10_sla_level_term
    id = 10

    sla_level_terms = fixture!('sla_level_terms')

    log_user('admin', 'admin') if sla_level_terms.any?

    priorities_by_name = IssuePriority.all.index_by(&:name)
    sla_types_by_name  = SlaType.all.index_by(&:name)

    sla_level_terms.each.with_index(1) do |(_key, sla_level_term), idx|

      sla_level_name = sla_level_term.fetch('sla_level')
      sla_type_name  = sla_level_term.fetch('sla_type')
      sla_priorities = sla_level_term.fetch('sla_priority')

      sla_level = SlaLevel.find_by!(name: sla_level_name)
      sla_type  = sla_types_by_name.fetch(sla_type_name)

      visit "/sla/levels/#{sla_level.id}/sla_terms"

      sla_priorities.each do |priority_name, value|
        priority = priorities_by_name.fetch(priority_name)

        field_id = "sla_level_sla_level_terms_attributes_#{sla_type.id}_#{priority.id}_term"
        fill_in field_id, with: value
      end

      take_doc_screenshot(format('%02d-01-%02d-01-sla_level_term-new.png', id, idx))
      click_button l('sla_label.sla_level_term.save')

      assert_text(l('sla_label.sla_level.notice_successful_update', id: "##{sla_level.id}"))
      take_doc_screenshot(format("%02d-01-%02d-02-sla_level_term-created.png", id, idx))

    end

    # take_doc_screenshot(format("%02d-02-sla_level_term-list.png", id)) if sla_level_terms.any?

  end
end