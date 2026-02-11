# frozen_string_literal: true

# File: redmine_sla/test/documentation/modules/02_sla_types_module.rb
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

module SlaTypesDocumentationTest

  def test_02_sla_type
    id=2

    sla_types = fixture!('sla_types')

    log_user('admin', 'admin') if sla_types.any?

    sla_types.each.with_index(1) do |sla_type, idx|

      sla_type_name = sla_type.fetch('name')

      visit '/sla/types/new'
      fill_in 'sla_type_name', with: sla_type_name

      take_doc_screenshot(format("%02d-01-%02d-01-sla_type-new.png", id, idx))
      click_button(l('sla_label.sla_type.new'))

      # Vérification de la création
      sla_type = SlaType.find_by!(name: sla_type_name)

      assert_text(l('sla_label.sla_type.notice_successful_create', id: "##{sla_type.id}"))
      take_doc_screenshot(format("%02d-01-%02d-02-sla_type-created.png", id, idx))

    end

    # take_doc_screenshot(format("%02d-02-sla_type-list.png",id)) if sla_types.any?

  end

end