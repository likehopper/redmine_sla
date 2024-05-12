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

module SlaTypesHelperSystemTest

  def create_sla_type(sla_type_name)
    visit '/sla/types/new'
    within('form#sla-type-form') do
      fill_in 'sla_type_name', :with => sla_type_name
      find('input[name=commit]').click
    end

    # find created issue
    sla_type = SlaType.find_by_name(sla_type_name)
    assert_kind_of SlaType, sla_type

    # check redirection
    find 'div#flash_notice',
      :visible => true,
      :text => l("sla_label.sla_type.notice_successful_create", :id => "##{sla_type.id}" )
    assert_equal sla_types_path, current_path

    # TODO : vérifier SlaTypes#show
    # visit "/sla/type/#{sla_types.id}"
    # compate sla_types attributs

    # check issue attributes
    assert_equal sla_type_name, sla_type.name
  end

  def update_sla_type
    sla_type = SlaType.generate!
    visit "/sla/types/#{sla_type.id}"
    page.first(:link, l('sla_label.sla.edit')).click
    within('form#sla-type-form') do
      fill_in 'Name', :with => 'mod SLA Type'
    end
    page.first(:button, l('sla_label.sla_type.save')).click
    # assert page.has_css?('#flash_notice')
    find 'div#flash_notice',
      :visible => true,
      :text => l("sla_label.sla_type.notice_successful_update", :id => "##{sla_type.id}" )
    assert_equal 'mod SLA Type', sla_type.reload.name
    # TODO : teste in SlaType#index after filtering
  end

  def destroy_sla_type
    sla_type = SlaType.generate!
    visit "/sla/types/#{sla_type.id}"
    page.first(:link, l('sla_label.sla_type.delete')).click
    page.accept_confirm /Are you sure/
    assert page.has_css?('#flash_notice'),
      :visible => true,
      :text => l(:notice_successful_delete)
    # TODO : teste in SlaType#index after filtering
  end

end