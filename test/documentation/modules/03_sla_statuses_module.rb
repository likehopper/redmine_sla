# frozen_string_literal: true

# File: redmine_sla/test/documentation/modules/03_sla_statuses_module.rb
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

module SlaStatusesDocumentationTest

  def test_03_sla_status
    id = 3

    sla_statuses = fixture!('sla_statuses')

    log_user('admin', 'admin') if sla_statuses.any?

    sla_statuses.each.with_index(1) do |sla_status, idx|
      sla_type_name     = sla_status.fetch('sla_type')
      issue_statuses     = sla_status.fetch('issue_statuses')

      issue_statuses.each.with_index(1) do |issue_status_name, idx2|

        visit '/sla/statuses/new'

        # Resolve names -> records
        sla_type = SlaType.find_by!(name: sla_type_name)
        issue_status = IssueStatus.find_by!(name: issue_status_name)

        # Select by id
        find('#sla_status_sla_type_id').find("option[value='#{sla_type.id}']").select_option
        find('#sla_status_status_id').find("option[value='#{issue_status.id}']").select_option

        take_doc_screenshot(format("%02d-01-%02d-%02d-01-sla_status-new.png", id, idx, idx2))
        click_button(l('sla_label.sla_status.new'))

        sla_status = SlaStatus.find_by!(
          sla_type_id: sla_type.id,
          status_id: issue_status.id
        )

      assert_text(l('sla_label.sla_status.notice_successful_create', id: "##{sla_status.id}"))
      take_doc_screenshot(format("%02d-01-%02d-%02d-02-sla_status-created.png", id, idx, idx2))        

      end

      # take_doc_screenshot(format("%02d-02-sla_status-list.png",id)) if sla_statuses.any?

    end

  end
end