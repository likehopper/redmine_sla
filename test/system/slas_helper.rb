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

# require File.expand_path('../../../application_system_test_case', __FILE__)

# class SlasSystemTest < ApplicationSystemTestCase
module SlasHelperSystemTest

  #include Redmine::I18n

  def contextual_menu_sla
    sla = Sla.find(1)

    visit '/sla/slas/'
    assert_text l('sla_label.sla.index')
    element = find('tr#entity_id_1')
    element.right_click
    assert_selector 'div#context-menu', visible: true
    assert_selector 'div#context-menu a', text: l(:button_show)
    find('div#context-menu a', text: l(:button_show)).click
    assert_current_path sla_path(sla)
    assert_text l('sla_label.sla.show')
    assert_text sla.name

    visit '/sla/slas/'
    assert_text l('sla_label.sla.index')
    element = find('tr#entity_id_1')
    element.right_click
    assert_selector 'div#context-menu', visible: true
    assert_selector 'div#context-menu a', text: l(:button_edit)
    find('div#context-menu a', text: l(:button_edit)).click
    assert_current_path edit_sla_path(sla)
    assert_text l('sla_label.sla.edit')
    assert_field 'sla_name', with: sla.name

    visit '/sla/slas/'
    assert_text l('sla_label.sla.index')
    element = find('tr#entity_id_1')
    element.right_click
    assert_selector 'div#context-menu', visible: true
    assert_selector 'div#context-menu a', text: l(:button_delete)
    accept_confirm do
      find('div#context-menu a', text: l(:button_delete)).click
    end
    assert_current_path slas_path()
    assert_text l(:notice_successful_delete)

  end 

  def create_sla(sla_name)
    visit '/sla/slas/new'
    within('form#sla-form') do
      fill_in 'sla_name', :with => sla_name
      find('input[name=commit]').click
    end

    # find created issue
    sla = Sla.find_by_name(sla_name)
    assert_kind_of Sla, sla

    # check redirection
    find 'div#flash_notice',
      :visible => true,
      :text => l("sla_label.sla.notice_successful_create", :id => "##{sla.id}" )
    assert_equal slas_path, current_path

    # TODO : vérifier SlaStatus#show
    # visit "/sla/statuses/#{sla_status.id}"
    # compate sla_status attributs

    # check issue attributes
    assert_equal sla_name, sla.name
  end

  def update_sla
    sla = Sla.generate!
    visit "/sla/slas/#{sla.id}"
    page.first(:link, l('sla_label.sla.edit')).click
    within('form#sla-form') do
      fill_in 'Name', :with => 'mod Sla'
    end
    page.first(:button, l('sla_label.sla.save')).click
    #assert page.has_css?('#flash_notice')
    find 'div#flash_notice',
      :visible => true,
      :text => l("sla_label.sla.notice_successful_update", :id => "##{sla.id}" )    
    assert_equal 'mod Sla', sla.reload.name
    # TODO : teste in Sla#index after filtering
  end

  def destroy_sla
    sla = Sla.generate!
    visit "/sla/slas/#{sla.id}"
    page.first(:link, l('sla_label.sla.delete')).click
    page.accept_confirm /Are you sure/
    assert page.has_css?('#flash_notice'),
      :visible => true,
      :text => l(:notice_successful_delete)
      # TODO : teste in Sla#index after filtering
  end

end