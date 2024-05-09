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
  
  # For display one SlaPriorityScf by issue in IssueHelper
  def find_by_issue(issue)
    self.find_by_priority_id(issue.custom_field_value(@scf.id))
  end

  # For display one SlaPriorityScf by priority_id in IssueHelper
  def find_by_priority_id(priority_id)
    # TODO : LOG : on ActiveRecord::RecordNotFound si find et nil si find_by
    return nil if priority_id.nil?
    priority = @scf.enumerations.active.find(priority_id) 
    self.create_value(priority.id,priority.name)
  end
  
  # For display all SlaPriority in SlaLevel views after self.create ( base on all values of the CustomField )
  def all
    @scf.enumerations.active { |id,name| self.create_value(id,name) }
  end

  private

  # TODO : identify source priority
  # def label / to_s / to_sym
  #   priority_name = "[CustomField] "+priority_id
  #   priority_name = "[IssuePriority] "+priority_name
  # end

end