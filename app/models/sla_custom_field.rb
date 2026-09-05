# frozen_string_literal: true

# File: redmine_sla/app/models/sla_custom_field.rb
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

class SlaCustomField < IssueCustomField
  
  include ActiveModel::Model

  def self.class
    Rails.logger.debug "==>> SlaCustomField self.class"
    "IssueCustomField"
  end

  # Only required, single-value enumeration fields can define SLA priorities.
  def self.find(custom_field_id)
    field = IssueCustomField.find_by(field_format: :enumeration, multiple: :false, is_required:true, id: custom_field_id)
    Rails.logger.error "SlaCustomField.find: no matching enumeration custom field for id=#{custom_field_id}" if field.nil?
    field
  end

  # To only list IssueCustomFields of type "enumeration" with single value in SlaLevel#edit
  def self.all
    fields = IssueCustomField.where(field_format: :enumeration, multiple: :false, is_required:true)
    Rails.logger.warn "SlaCustomField.all: no enumeration custom field available" if fields.empty?
    fields
  end

end
