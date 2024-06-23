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

module SlaLevelsHelperSystemTest

  def contextual_menu_sla_level
    sla_level = SlaLevel.find(1)

    visit '/sla/levels?sort=id'
    assert_text l('sla_label.sla_level.index')
    element = find('tr#entity_id_1')
    element.right_click
    assert_selector 'div#context-menu', visible: true
    assert_selector 'div#context-menu a', text: 'Show'
    find('div#context-menu a', text: l(:button_show)).click
    assert_current_path sla_level_path(sla_level)
    assert_text l('sla_label.sla_level.show')
    assert_text sla_level.name

    visit '/sla/levels?sort=id'
    assert_text l('sla_label.sla_level.index')
    element = find('tr#entity_id_1')
    element.right_click
    assert_selector 'div#context-menu', visible: true
    assert_selector 'div#context-menu a', text: l(:button_edit)
    find('div#context-menu a', text: l(:button_edit)).click
    assert_current_path edit_sla_level_path(sla_level)
    assert_text l('sla_label.sla_level.edit')
    assert_field 'sla_level_name', with: sla_level.name

    visit '/sla/levels?sort=id'
    assert_text l('sla_label.sla_level.index')
    element = find('tr#entity_id_1')
    element.right_click
    assert_selector 'div#context-menu', visible: true
    assert_selector 'div#context-menu a', text: l(:button_delete)
    accept_confirm do
      find('div#context-menu a', text: l(:button_delete)).click
    end
    assert_current_path sla_levels_path(sort: :id)
    assert_text l(:notice_successful_delete)
    
  end 

  def create_sla_level(sla_level_name,sla_level_sla_name,sla_level_sla_calendar_name)
    visit '/sla/levels/new'
    within('form#sla-level-form') do
      fill_in 'sla_level_name', :with => sla_level_name
      select sla_level_sla_name, from: "sla_level_sla_id"
      select sla_level_sla_calendar_name, from: "sla_level_sla_calendar_id"
      find('input[name=commit]').click
    end

    # find created issue
    sla_level = SlaLevel.find_by_name(sla_level_name)
    assert_kind_of SlaLevel, sla_level

    # check redirection
    find 'div#flash_notice',
      :visible => true,
      :text => l("sla_label.sla_level.notice_successful_create", :id => "##{sla_level.id}" )
    assert_equal sla_levels_path, current_path

    # TODO : vérifier SlaLevel#show
    # visit "/sla/leveles/#{sla_level.id}"
    # compate sla_level attributs

    # check issue attributes
    assert_equal sla_level_name, sla_level.name
  end

  def update_sla_level
    sla_level = SlaLevel.generate!
    visit "/sla/levels/#{sla_level.id}"
    page.first(:link, l('sla_label.sla_level.edit')).click
    within('form#sla-level-form') do
      fill_in 'Name', :with => 'mod SLA Calendar'
    end
    page.first(:button, l('sla_label.sla_level.save')).click
    # assert page.has_css?('#flash_notice')
    find 'div#flash_notice',
      :visible => true,
      :text => l('sla_label.sla_level.notice_successful_update', :id => "##{sla_level.id}" )    
    assert_equal 'mod SLA Calendar', sla_level.reload.name
    # TODO : teste in SlaLevel#index after filtering
  end

  def destroy_sla_level
    sla_level = SlaLevel.generate!
    visit "/sla/levels/#{sla_level.id}"
    page.first(:link, l('sla_label.sla_level.delete')).click
    page.accept_confirm /Are you sure/
    assert page.has_css?('#flash_notice'),
      :visible => true,
      :text => l(:notice_successful_delete)
    # TODO : teste in SlaLevel#index after filtering
  end

end