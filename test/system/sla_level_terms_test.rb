# frozen_string_literal: true

# File: redmine_sla/test/system/sla_level_terms_helper.rb
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

class SlaLevelTermsHelperSystemTest < ApplicationSlaSystemTestCase

  test "contextual_menu_sla_level_term" do
    sla_level_term = SlaLevelTerm.find(1)

    log_user('admin', 'admin')

    visit '/sla/level_terms?sort=id'
    assert_text l('sla_label.sla_level_term.index')
    element = find('tr#entity_id_1 td.sla_priority_id')
    element.right_click
    assert_selector 'div#context-menu', visible: true
    assert_selector 'div#context-menu a', text: 'Show'
    find('div#context-menu a', text: l(:button_show)).click
    assert_current_path sla_level_term_path(sla_level_term)
    assert_text l('sla_label.sla_level_term.show')
    assert_text sla_level_term.sla_level.name

    visit '/sla/level_terms?sort=id'
    assert_text l('sla_label.sla_level_term.index')
    element = find('tr#entity_id_1 td.sla_priority_id')
    element.right_click
    assert_selector 'div#context-menu', visible: true
    assert_selector 'div#context-menu a', text: l(:button_edit)
    find('div#context-menu a', text: l(:button_edit)).click
    assert_current_path sla_terms_sla_level_path(sla_level_term.sla_level.id)
    assert_text l('sla_label.sla_level_term.edit')
    assert_field 'sla_level_sla_level_terms_attributes_1_1_term', with: 120

    visit '/sla/level_terms?sort=id'
    assert_text l('sla_label.sla_level_term.index')
    element = find('tr#entity_id_1 td.sla_priority_id')
    element.right_click
    assert_selector 'div#context-menu', visible: true
    assert_selector 'div#context-menu a', text: l(:button_delete)
    accept_confirm do
      find('div#context-menu a', text: l(:button_delete)).click
    end
    assert_current_path sla_level_terms_path(sort: :id)
    assert_text l(:notice_successful_delete)
    
  end 

  # SlaLevelTerm create/update involve by SlaLevel#sla_terms !
  test "create_update_sla_level_term" do
    sla_level = SlaLevel.generate!

    log_user('admin', 'admin')

    visit "/sla/levels/#{sla_level.id}/sla_terms"
    within('form#sla-level-terms-form') do
      fill_in "sla_level_sla_level_terms_attributes_1_1_term", :with => 60
      find('input[name=commit]').click
    end

    # find created issue
    sla_level_term = SlaLevelTerm.find_by(sla_level_id: sla_level.id,sla_type_id: 1,sla_priority_id: 1)

    # check redirection
    find 'div#flash_notice',
      :visible => true,
      :text => l("sla_label.sla_level.notice_successful_update", :id => "##{sla_level.id}" )
    assert_equal sla_levels_path, current_path

    # TODO : vérifier SlaLevelTerm#show
    # visit "/sla/level_termes/#{sla_level_term.id}"
    # compate sla_level_term attributs

    # check issue attributes
    assert_equal 60, sla_level_term.term
  end

  test "destroy_sla_level_term" do 
    sla_level_term = SlaLevelTerm.generate!

    log_user('admin', 'admin')

    visit "/sla/level_terms/#{sla_level_term.id}"
    page.first(:link, l('sla_label.sla_level_term.delete')).click
    page.accept_confirm /Are you sure/
    assert page.has_css?('#flash_notice'),
      :visible => true,
      :text => l(:notice_successful_delete)
    # TODO : check in SlaLevelTerm#index after filtering
  end

end