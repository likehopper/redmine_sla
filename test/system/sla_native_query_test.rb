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

# File: redmine_sla/test/system/sla_native_query_test.rb
# Purpose:
#   Verify SLA grouping labels and counts in native Redmine lists.
#
# Redmine SLA - Redmine's Plugin

require_relative '../application_sla_system_test_case'

class SlaNativeQuerySystemTest < ApplicationSlaSystemTestCase
  def teardown
    User.current = nil
    super
  end

  ['issues', 'time_entries'].each do |resource|
    test "native #{resource} list displays SLA groups with their correct counts" do
      User.current = User.find(1)
      project = Project.find(1)
      records = if resource == 'issues'
                  project.issues.to_a
                else
                  activity = TimeEntryActivity.create!(name: 'SLA browser test', active: true)
                  project.issues.each do |issue|
                    TimeEntry.create!(project: project, issue: issue, user: User.find(1),
                                      activity: activity, hours: 1, spent_on: Date.today)
                  end
                  TimeEntry.create!(project: project, user: User.current, activity: activity,
                                    hours: 1, spent_on: Date.today)
                  project.time_entries.includes(:issue).to_a
                end
      expected = records.group_by do |record|
        issue = resource == 'issues' ? record : record.issue
        issue&.get_sla_respect(1)
      end.transform_keys do |respect|
        respect.nil? ? "(#{l(:label_blank_value)})" : l(respect ? :general_text_Yes : :general_text_No)
      end.transform_values(&:size)

      log_user('admin', 'admin')
      field = resource == 'issues' ? 'status_id' : 'spent_on'
      params = URI.encode_www_form('set_filter' => '1', 'f[]' => field,
                                   "op[#{field}]" => '*', "v[#{field}][]" => '',
                                   'group_by' => 'get_sla_respect_1',
                                   'sort' => 'get_sla_respect_1:asc', 'per_page' => '100',
                                   'c[]' => ['id', 'get_sla_level', 'get_sla_respect_1'])
      visit "/projects/#{project.identifier}/#{resource}?#{params}"

      assert_selector 'tr.group', count: expected.size
      actual = all('tr.group').to_h do |row|
        [row.find('.name').text, row.find('.count').text.to_i]
      end
      assert_equal expected, actual
    end
  end
end
