# frozen_string_literal: true

# File: redmine_sla/test/documentation/modules/09_all_module.rb
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

# Load all documentation modules once
require_relative "01_slas_module"
require_relative "02_sla_types_module"
require_relative "03_sla_statuses_module"
require_relative "04_sla_calendars_module"
require_relative "05_sla_holidays_module"
require_relative "06_sla_calendar_holidays_module"
require_relative "07_projects_module"
require_relative "08_custom_fields_module"
require_relative "09_sla_levels_module"
require_relative "10_sla_level_terms_module"
require_relative "11_project_settings_module"
require_relative "12_issues_module"

# Aggregate includes in a single mixin
module RedmineSlaDocumentationModules
  include SlasDocumentationTest
  include SlaTypesDocumentationTest
  include SlaStatusesDocumentationTest
  include SlaCalendarsDocumentationTest
  include SlaHolidaysDocumentationTest
  include SlaCalendarHolidaysDocumentationTest
  include ProjectsDocumentationTest
  include CustomFieldsDocumentationTest
  include SlaLevelsDocumentationTest
  include SlaLevelTermsDocumentationTest
  include ProjectSettingsDocumentationTest
  include IssuesDocumentationTest
end