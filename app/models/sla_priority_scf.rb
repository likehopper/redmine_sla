# frozen_string_literal: true

# Redmine - project management software
# Copyright (C) 2006-2023  Jean-Philippe Lang
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

class SlaPriorityScf < SlaPriority

  unloadable

  include ActiveModel::Model

  def initialize(custom_field_id)
    @scf = SlaCustomField.find(custom_field_id)
  end
  
  # For display one SlaPriority in IssueHelper
  def find_by_issue(issue)
    sla_priority = issue.custom_value_for(@scf.id)
    SlaPriorityValue.new({ id: sla_priority, name: sla_priority })
  end
  
  # For display all SlaPriority in SlaLevel views after self.create ( base on all values of the CustomField )
  def all
    @scf.possible_values.map { |name| SlaPriorityValue.new({ id: name, name: name }) }
  end  
  
end