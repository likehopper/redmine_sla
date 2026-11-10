# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

# File: redmine_sla/app/models/sla_type.rb
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

class SlaType < ActiveRecord::Base

  has_many :sla_level_terms

  has_many :sla_levels, through: :sla_level_terms
  has_many :slas, through: :sla_levels
  has_many :sla_project_trackers, through: :slas

  include Redmine::SafeAttributes
  include RedmineSla::InvalidatesSlaCache

  # Redmine models normally get this for free through ApplicationRecord (see
  # lib/redmine/preparation.rb), but this plugin's models inherit directly
  # from ActiveRecord::Base, so it needs including explicitly here.
  include Redmine::Acts::Positioned
  acts_as_positioned

  scope :visible, ->(*args) { where(SlaType.visible_condition(args.shift || User.current, *args)) }
  scope :sorted, -> { order(:position) }

  validates_presence_of :name

  validates_uniqueness_of :name, :case_sensitive => false

  safe_attributes *%w[name description position]

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

  # Print text for link objects
  def to_s
    self.name
  end

  private

  # Saves only change metadata or position, and a new type has no terms yet.
  def sla_cache_preserving_change?
    true
  end

  # The database cascade deletes this type's terms without callbacks, which
  # can make a level ineligible for an issue priority.
  def sla_ids_for_cache_invalidation
    terms = SlaLevelTerm.unscoped.where(sla_type_id: id).select(:sla_level_id)
    SlaLevel.unscoped.where(id: terms).distinct.pluck(:sla_id)
  end

end