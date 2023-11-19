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

class SlasSystemTest < ApplicationSystemTestCase

  include Redmine::I18n

  test "create_sla" do

    log_user('admin', 'admin')
    visit '/sla/slas/new'
    within('form#sla-form') do
      fill_in 'sla_name', :with => 'new Sla'
      find('input[name=commit]').click
    end

    # find created issue
    sla = Sla.find_by_name("new Sla")
    assert_kind_of Sla, sla

    # check redirection
    find 'div#flash_notice',
      :visible => true,
      :text => l("sla_label.sla.notice_successful_create", :id => "##{sla.id}" )
    assert_equal slas_path, current_path

    # check issue attributes
    assert_equal 'new Sla', sla.name
  end

  test "update sla name" do
    sla = Sla.generate!
    log_user('admin', 'admin')
    visit "/sla/slas/#{sla.id}"
    page.first(:link, 'Edit').click
    within('form#sla-form') do
      fill_in 'Name', :with => 'mod Sla'
    end
    page.first(:button, l('sla_label.sla.edit')).click
    assert page.has_css?('#flash_notice')
    assert_equal 'mod Sla', sla.reload.name
  end

  test "removing sla shows confirm dialog" do
    sla = Sla.generate!
    log_user('admin', 'admin')
    visit "/sla/slas/#{sla.id}"
    page.accept_confirm /Are you sure/ do
      first('#content a.icon-del').click
    end
  end

end