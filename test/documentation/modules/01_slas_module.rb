# frozen_string_literal: true

# File: redmine_sla/test/documentation/modules/01_slas_module.rb
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

module SlasDocumentationTest

  def test_01_sla
    id=1

    slas = fixture!('slas')
    
    log_user('admin', 'admin') if slas.any?

    slas.each.with_index(1) do |sla,idx|

      sla_name = sla.fetch('name')

      visit '/sla/slas/new'
      fill_in 'sla_name', with: sla_name

      take_doc_screenshot(format('%02d-01-%02d-01-sla-new.png', id, idx))
      click_button(l('sla_label.sla.new'))

      # Vérification de la création
      sla = Sla.find_by!(name: sla_name)

      assert_text(l('sla_label.sla.notice_successful_create', id: "##{sla.id}"))
      take_doc_screenshot(format("%02d-01-%02d-02-sla-created.png", id, idx))
      
    end

    # take_doc_screenshot(format("%02d-02-sla-list.png",id)) if slas.any?

  end

end