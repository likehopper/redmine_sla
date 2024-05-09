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
    SlaPriority.create(issue.get_sla_level[:custom_field_id]).find_by_issue(issue)
  end

  # For display one SlaPriority by Issue in IssueHelper
  def find_by_issue(issue)
    self.find_by_priority_id(issue.priority_id)
  end

  # For display one SlaPriority by Priority in Query/Filter
  def find_by_priority_id(priority_id)
    # TODO : LOG : on ActiveRecord::RecordNotFound si find et nil si find_by
    priority = IssuePriority.active.find(priority_id)
    self.create_value(priority.id,priority.name)
  end  

  # For display all SlaPriority in SlaLevel views after self.create ( base on all values of IssuePriority )
  def all
    IssuePriority.active.order(position: :asc) { |id,name| self.create_value(id,name) }
  end

  # TODO : all ( IssuePriority + ScfPriority ) use in SlaLevel for make filter !!!
  def self.all
    priorities = []
    SlaLevel.joins(:sla_level_terms).distinct.pluck(:custom_field_id,:sla_priority_id).each { |custom_field_id,priority_id|
      priorities << SlaPriority.create(custom_field_id).find_by_priority_id(priority_id)
    }
    priorities
  end

  private

  def create_value(priority_id,priority_name)
    SlaPriorityValue.new({ id: priority_id, name: priority_name })
  end
  
  # TODO : identify source priority
  # def label / to_s / to_sym
  #   priority_name = "[CustomField] "+priority_id
  #   priority_name = "[IssuePriority] "+priority_name
  # end  
  
end