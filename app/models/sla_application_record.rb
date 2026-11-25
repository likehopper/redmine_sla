# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

# File: redmine_sla/app/models/sla_application_record.rb
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

# Base class of the plugin's models.
#
# Redmine 5.1 extends ActiveRecord::Base itself with its attribute label
# lookup (field_* translations) and its Positioned, Mentionable and I18n
# modules. Redmine 6 moved all of them to ApplicationRecord, which Redmine 5.1
# does not define. Inheriting from ApplicationRecord when it exists gives the
# plugin's models the same behavior on every supported Redmine version.
class SlaApplicationRecord < (defined?(ApplicationRecord) ? ApplicationRecord : ActiveRecord::Base)
  self.abstract_class = true
end
