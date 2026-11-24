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

# File: redmine_sla/test/unit/sla_attribute_label_test.rb
# Purpose:
#   Form labels and validation messages name attributes through
#   human_attribute_name. Redmine resolves it from its field_* translations,
#   on ActiveRecord::Base in Redmine 5.1 and on ApplicationRecord since
#   Redmine 6: the SLA models must get the same labels on every version.
#
# Redmine SLA - Redmine's Plugin

require File.expand_path('../../application_sla_units_test_case', __FILE__)

class SlaAttributeLabelTest < ApplicationSlaUnitsTestCase
  SLA_MODELS = [
    Sla, SlaCache, SlaCacheSpent, SlaCalendar, SlaCalendarHoliday, SlaHoliday,
    SlaLevel, SlaLevelTerm, SlaProjectTracker, SlaSchedule, SlaStatus, SlaType
  ].freeze

  test "every SLA model inherits the plugin base class" do
    SLA_MODELS.each do |model|
      assert model < SlaApplicationRecord, "#{model.name} should inherit SlaApplicationRecord"
    end
  end

  test "attributes reuse the Redmine core field translations" do
    %i[en fr].each do |locale|
      I18n.with_locale(locale) do
        assert_equal I18n.t(:field_project), SlaProjectTracker.human_attribute_name(:project_id)
        assert_equal I18n.t(:field_tracker), SlaProjectTracker.human_attribute_name(:tracker_id)
        assert_equal I18n.t(:field_status), SlaStatus.human_attribute_name(:status_id)
        assert_equal I18n.t(:field_priority), SlaLevelTerm.human_attribute_name(:priority_id)
        assert_equal I18n.t(:field_issue), SlaCache.human_attribute_name(:issue_id)
      end
    end
  end

  test "attributes without an activerecord translation use the plugin field translations" do
    %i[en fr].each do |locale|
      I18n.with_locale(locale) do
        assert_equal I18n.t(:field_sla), SlaProjectTracker.human_attribute_name(:sla_id)
        assert_equal I18n.t(:field_start_time), SlaSchedule.human_attribute_name(:start_time)
        assert_equal I18n.t(:field_custom_field), SlaLevel.human_attribute_name(:custom_field_id)
      end
    end
  end

  test "validation messages name the attribute in the current language" do
    I18n.with_locale(:fr) do
      sla_project_tracker = SlaProjectTracker.new
      assert_not sla_project_tracker.valid?
      assert_includes sla_project_tracker.errors.full_messages.join("\n"), I18n.t(:field_project)
    end
  end
end
