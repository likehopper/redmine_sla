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

require File.expand_path('../../application_system_test_case', __FILE__)

class SlaTypesSystemTest < ApplicationSystemTestCase

  include Redmine::I18n

  test "create_sla_type" do

    log_user('admin', 'admin')
    visit '/sla/types/new'
    within('form#sla_type-form') do
      fill_in 'sla_type_name', :with => 'new SlaType'
      find('input[name=commit]').click
    end

    # find created issue
    sla_type = SlaType.find_by_name("new SlaType")
    assert_kind_of SlaType, sla_type

    # check redirection
    find 'div#flash_notice',
      :visible => true,
      :text => l("sla_label.sla_type.notice_successful_create", :id => "##{sla_type.id}" )
    assert_equal sla_types_path, current_path

    # check issue attributes
    assert_equal 'new SlaType', sla_type.name
  end

  test "update sla_type name" do
    sla_type = SlaType.generate!
    log_user('admin', 'admin')
    visit "/sla/types/#{sla_type.id}"
    page.first(:link, 'Edit').click
    within('form#sla_type-form') do
      fill_in 'Name', :with => 'mod SlaType'
    end
    page.first(:button, l('sla_label.sla_type.edit')).click
    assert page.has_css?('#flash_notice')
    assert_equal 'mod SlaType', sla_type.reload.name
  end

  test "removing sla_type shows confirm dialog" do
    sla_type = SlaType.generate!
    log_user('admin', 'admin')
    visit "/sla/types/#{sla_type.id}"
    page.accept_confirm /Are you sure/ do
      first('#content a.icon-del').click
    end
  end

end