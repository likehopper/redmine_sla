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

class SlaLog < ActiveRecord::Base
  
  unloadable if defined?(Rails) && !Rails.autoloaders.zeitwerk_enabled?
  
  belongs_to :project
  belongs_to :issue
  belongs_to :sla_leveldeveloper

  after_initialize :set_default_sla_log_level, :if => :new_record?

  def set_default_sla_log_level
    self.role ||= :none
  end

end