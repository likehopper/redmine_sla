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

class SlaCustomField < IssueCustomField
  
  include ActiveModel::Model

  def self.class
    Rails.logger.debug "==>> SlaCustomField self.class"
    "IssueCustomField"
  end

  # TODO : filter on issue with an other method self.find_by_issue ( issue.available_custom_fields.find { |field| field.id == custom_field_id } )
  def self.find(custom_field_id)
    # TODO : LOG : ERROR : if nil !!!
    IssueCustomField.find_by(field_format: :enumeration, multiple: :false, is_required:true, id: custom_field_id)
  end 

  # To only list IssueCustomFields of type "enumeration" with single value in SlaLevel#edit
  def self.all
    # TODO : LOG : NOTICE : if nil 
    IssueCustomField.where(field_format: :enumeration, multiple: :false, is_required:true)
  end

end