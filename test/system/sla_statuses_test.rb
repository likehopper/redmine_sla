# frozen_string_literal: true

# File: redmine_sla/test/system/sla_statuses_helper.rb
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

require_relative "../application_sla_system_test_case"

class SlaStatusesHelperSystemTest < ApplicationSlaSystemTestCase

  test "contextual_menu_sla_status" do
    sla_status = SlaStatus.find(1)

    log_user('admin', 'admin')

    visit '/sla/statuses/'
    assert_text l('sla_label.sla_status.index')
    element = find('tr#entity_id_1')
    element.right_click
    assert_selector 'div#context-menu', visible: true
    assert_selector 'div#context-menu a', text: 'Show'
    find('div#context-menu a', text: l(:button_show)).click
    assert_current_path sla_status_path(sla_status)
    assert_text l('sla_label.sla_status.show')
    assert_text sla_status.sla_type.name

    visit '/sla/statuses/'
    assert_text l('sla_label.sla_status.index')
    element = find('tr#entity_id_1')
    element.right_click
    assert_selector 'div#context-menu', visible: true
    assert_selector 'div#context-menu a', text: l(:button_edit)
    find('div#context-menu a', text: l(:button_edit)).click
    assert_current_path edit_sla_status_path(sla_status)
    assert_text l('sla_label.sla_status.edit')
    assert_select 'sla_status_sla_type_id' do
      assert_select 'sla_status[sla_type_id]', text: sla_status.sla_type.name
    end

    visit '/sla/statuses/'
    assert_text l('sla_label.sla_status.index')
    element = find('tr#entity_id_1')
    element.right_click
    assert_selector 'div#context-menu', visible: true
    assert_selector 'div#context-menu a', text: l(:button_delete)
    accept_confirm do
      find('div#context-menu a', text: l(:button_delete)).click
    end
    assert_current_path sla_statuses_path()
    assert_text l(:notice_successful_delete)
    
  end   

  test "create_sla_status()" do
    issue_status_name = 'New'

    sla_type = SlaType.generate!

    log_user('admin', 'admin')

    visit '/sla/statuses/new'
    within('form#sla-status-form') do
      select sla_type.name, from: "sla_status_sla_type_id"
      select issue_status_name, from: "sla_status_status_id"
      find('input[name=commit]').click
    end

    # find created issue
    sla_status = SlaStatus.find_by(sla_type_id: SlaType.find_by(name: sla_type.name), status_id: IssueStatus.find_by(name: issue_status_name))
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
    assert_equal sla_type.name, sla_status.sla_type.name
    assert_equal issue_status_name, sla_status.status.name
  end

  test "update_sla_status" do
    sla_status = SlaStatus.generate!
    sla_type = SlaType.generate!

    log_user('admin', 'admin')

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

  test "destroy_sla_status" do 
    sla_status = SlaStatus.generate!

    log_user('admin', 'admin')

    visit "/sla/statuses/#{sla_status.id}"
    page.first(:link, l('sla_label.sla_status.delete')).click
    page.accept_confirm /Are you sure/
    assert page.has_css?('#flash_notice'),
      :visible => true,
      :text => l(:notice_successful_delete)       
    # TODO : teste in SlaStatus#index after filtering
  end

end