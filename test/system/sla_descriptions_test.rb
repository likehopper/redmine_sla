# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Redmine SLA - service level agreement plugin
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

# File: redmine_sla/test/system/sla_descriptions_test.rb
# Purpose:
#   Verify the description wiki toolbar, rendered text and list tooltips.
#
# Redmine SLA - Redmine's Plugin

require_relative '../application_sla_system_test_case'

class SlaDescriptionsSystemTest < ApplicationSlaSystemTestCase
  test "description wiki toolbar saves formatted text and clearing removes it" do
    log_user('admin', 'admin')
    with_settings :text_formatting => 'common_mark' do
      visit '/sla/slas/1/edit'
      assert_selector '#sla_description.wiki-edit'
      assert_selector '.jstElements button', :minimum => 1
      fill_in 'sla_description', :with => '**Answer** & support'
      click_button l('sla_label.sla.save')
      assert_current_path '/sla/slas'
      assert_selector 'tr#entity_id_1 td.name span[title="Answer & support"]'
      visit '/sla/slas/1'
      assert_selector 'div.sla-description strong', :text => 'Answer'
      visit '/sla/slas/1/edit'
      fill_in 'sla_description', :with => ''
      click_button l('sla_label.sla.save')
      assert_current_path '/sla/slas'
      assert_no_selector 'tr#entity_id_1 td.name span[title]'
      visit '/sla/slas/1'
      assert_no_selector 'div.sla-description'
    end
  end

  test "description block columns render in the browser without an error" do
    log_user('admin', 'admin')
    %w[slas calendars levels].each do |resource|
      visit "/sla/#{resource}?set_filter=1&c[]=name&c[]=description"
      assert_selector 'tr#entity_id_1 + tr td.description[colspan="3"]'
      assert_no_selector '#errorExplanation'
    end
  end
end
