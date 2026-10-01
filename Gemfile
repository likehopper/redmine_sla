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

# File: redmine_sla/Gemfile
# Purpose:
#   Declare Ruby gem dependencies required by the Redmine SLA plugin.
#   These gems must be installed in the Redmine environment in order for
#   the plugin features to operate correctly (nested forms, time parsing).

# Provides nested form fields used in SLA configuration screens
gem "nested_form"

# Natural language time parsing (e.g. "5 minutes", "2 hours")
gem "chronic"

# Duration parsing and formatting used for SLA time representation
gem "chronic_duration"

# Prevent Ruby 3.5 deprecation warnings (ostruct removed from default gems)
gem 'ostruct', require: false
