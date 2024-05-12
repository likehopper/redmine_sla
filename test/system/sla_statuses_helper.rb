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

module SlaStatusesHelperSystemTest

  def create_sla_status(sla_type_name,issue_status_name)
    visit '/sla/statuses/new'
    within('form#sla-status-form') do
      select sla_type_name, from: "sla_status_sla_type_id"
      select issue_status_name, from: "sla_status_status_id"
      find('input[name=commit]').click
    end

    # find created issue
    sla_status = SlaStatus.find_by(sla_type_id: SlaType.find_by(name: sla_type_name), status_id: IssueStatus.find_by(name: issue_status_name))
    assert_kind_of SlaStatus, sla_status

    # check redirection
    find 'div#flash_notice',
      :visible => true,
      :text => l("sla_label.sla_status.notice_successful_create", :id => "##{sla_status.id}" )
    assert_equal sla_statuses_path, current_path

    # TODO : vérifier SlaStatus#show
    # visit "/sla/statuses/#{sla_status.id}"
    # compate sla_status attributs

    # check issue attributes
    assert_equal sla_type_name, sla_status.sla_type.name
    assert_equal issue_status_name, sla_status.status.name
  end

  def update_sla_status
    sla_status = SlaStatus.generate!
    sla_type = SlaType.generate!
    visit "/sla/statuses/#{sla_status.id}"
    page.first(:link,  l('sla_label.sla_status.edit')).click
    within('form#sla-status-form') do
      select sla_type.name, :from => 'sla_status[sla_type_id]'
      select 'New', :from => 'sla_status[status_id]'
    end
    page.first(:button, l('sla_label.sla_status.save')).click
    # assert page.has_css?('#flash_notice')
    find 'div#flash_notice',
      :visible => true,
      :text => l("sla_label.sla_status.notice_successful_update", :id => "##{sla_status.id}" )
    assert_equal sla_type.id, sla_status.reload.sla_type.id
    assert_equal 'New', sla_status.reload.status.name
    # TODO : teste in SlaStatus#index after filtering
  end

  def destroy_sla_status
    sla_status = SlaStatus.generate!
    visit "/sla/statuses/#{sla_status.id}"
    page.first(:link, l('sla_label.sla_status.delete')).click
    page.accept_confirm /Are you sure/
    assert page.has_css?('#flash_notice'),
      :visible => true,
      :text => l(:notice_successful_delete)       
    # TODO : teste in SlaStatus#index after filtering
  end

end