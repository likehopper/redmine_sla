# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

# File: redmine_sla/app/models/sla_status.rb
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

class SlaStatus < ActiveRecord::Base
  
  belongs_to :sla_type
  belongs_to :status, :class_name => 'IssueStatus'

  include Redmine::SafeAttributes

  scope :visible, ->(*args) { where(SlaStatus.visible_condition(args.shift || User.current, *args)) }

  # The list query needs both tables for its sortable columns.
  scope :with_references, -> { joins(:sla_type, :status) }

  validates_presence_of :sla_type
  validates_presence_of :status

  validates_associated :sla_type
  validates_associated :status
  
  validates_uniqueness_of :sla_type_id, :scope => [ :status_id ]

  safe_attributes *%w[sla_type_id status_id]

  # Counted statuses decide the spent time of their SLA type, not the SLA
  # level: drop only that type's incremental totals, recalculated on demand.
  after_save :invalidate_sla_spent_cache, if: :saved_changes?
  after_destroy :invalidate_sla_spent_cache

  # No selection limitations
  def self.visible_condition(user, options = {})
    '1=1'
  end

  # For index and show
  def visible?(user=User.current)
    user.allowed_to?(:manage_sla, nil, global: true)
  end

  # For create and update
  def editable?(user=User.current)
    user.allowed_to?(:manage_sla, nil, global: true)
  end

  # For destroy
  def deletable?(user=User.current)
    user.allowed_to?(:manage_sla, nil, global: true)
  end

  private

  def invalidate_sla_spent_cache
    # Moving a status to another type changes the totals of both types.
    type_ids = [sla_type_id, sla_type_id_before_last_save].compact.uniq
    SlaCacheSpent.unscoped.where(sla_type_id: type_ids).delete_all
  end

end
