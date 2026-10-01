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
# File: redmine_sla/config/initializers/inflections.rb
# Purpose:
#   Define custom inflection rules for the Redmine SLA plugin.
#   In particular, ensure that the singular/plural forms of "sla_cache"
#   are handled correctly by ActiveRecord (e.g. model ↔ table names).

ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.irregular 'sla_cache', 'sla_caches'
end