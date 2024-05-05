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

class SlaPriority

  unloadable

  include ActiveModel::Model

  class SlaPriorityValue
    attr_accessor :id, :name
    def initialize(hash)
      @id = hash[:id]
      @name = hash[:name]
    end
  end  

  # Use in management ( cf. nested & show in view/sla_levels )
  def self.create(custom_field_id)
    if custom_field_id.nil? 
      SlaPriority.new
    else
      SlaPriorityScf.new(custom_field_id)
    end
  end  

  # Use for display issues
  def self.create_by_issue(issue)
    custom_field_id = issue.get_sla_level[:custom_field_id]
    ( custom_field_id.nil? ? SlaPriority.new.find_by_issue(issue) : SlaPriorityScf.new(custom_field_id).find_by_issue(issue) )
  end  

  # For display one SlaPriority in IssueHelper
  def find_by_issue(issue)
    IssuePriority.find_by(id: issue.priority_id) { |id,name| SlaPriorityValue.new({ id: id, name: name }) }
  end

  # For display all SlaPriority in SlaLevel views after self.create ( base on all values of IssuePRiority )
  def all
    IssuePriority.all.order(:position).each { |id,name| SlaPriorityValue.new({ id: id, name: name }) }    
  end

  # TODO : all ( IssuePriority + ScfPriority ) use in SlaLevel for make filter !!!
  
end