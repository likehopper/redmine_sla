# frozen_string_literal: true

# File: redmine_sla/app/models/sla_cache_spent.rb
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

class SlaCacheSpent < ActiveRecord::Base

  belongs_to :sla_cache
  belongs_to :sla_type
  belongs_to :project
  belongs_to :issue

  has_one :sla_level, through: :sla_cache

  include Redmine::SafeAttributes
  #safe_attributes *%w[sla_cache_id sla_type_id updated_on spent]
  safe_attributes *%w[]

  # Join order is important
  # default_scope { joins(:project,:issue,sla_cache: :sla_level) }
  default_scope { joins(:project,:issue,:sla_cache,:sla_type) }

  scope :visible, ->(*args) { where(SlaCacheSpent.visible_condition(args.shift || User.current, *args)) }

  # Selection limitations for users based on access issues
  def self.visible_condition(user=User.current, options = {})
    issue_condition = Issue.visible_condition(user, options)
    project_condition = Project.allowed_to_condition(user, :view_sla, options)
    "(#{issue_condition}) AND (#{project_condition})"
  end

  # For index and refresh
  def visible?(user=User.current)
    user.allowed_to?(:view_sla, self.project) && self.issue.visible?
  end

  # For create and update
  def editable?(user=nil)
    false
  end

  # For destroy and purge
  def deletable?(user=User.current)
    user.allowed_to?(:manage_sla, self.project) && self.issue.visible?
  end
  
  def self.find_by_issue_and_type_id(issue,sla_type_id)
    RedmineSla::DbDialect.ensure_recursion_depth!
    ActiveRecord::Base.connection.execute(sanitize_sql(["SELECT sla_get_spent(?,?) ; ", issue.id, sla_type_id]))
    self.find_by(issue_id: issue.id,sla_type_id: sla_type_id)
  end

  # Class method for refresh cache
  def self.refresh_by_issue_id(issue_id)
    RedmineSla::DbDialect.ensure_recursion_depth!
    SlaType.all.each do |sla_type|
      ActiveRecord::Base.connection.execute(sanitize_sql(["SELECT sla_get_spent(?,?) ; ", issue_id, sla_type.id]))
    rescue ActiveRecord::StatementInvalid => e
      Rails.logger.error "[SLA] SlaCacheSpent.refresh_by_issue_id failed for issue ##{issue_id}, sla_type ##{sla_type.id}: #{e.message}"
    end
  end

  # Class method for refresh cache
  def refresh
    RedmineSla::DbDialect.ensure_recursion_depth!
    ActiveRecord::Base.connection.execute(self.class.sanitize_sql(["SELECT sla_get_spent(?,?) ; ", self.sla_cache.issue_id, self.sla_type.id]))
  end

  def self.purge(project)
    if ( project.nil? )
      if RedmineSla::DbDialect.adapter == :mysql
        # DELETE, not TRUNCATE: on MySQL/InnoDB, TRUNCATE is DDL and causes
        # an implicit COMMIT, silently ending any enclosing transaction
        # (breaking transactional test isolation and any caller-managed
        # transaction). DELETE participates in the transaction normally.
        # Separate execute calls because Rails' mysql2 connections don't
        # enable multi-statement execution by default.
        connection = ActiveRecord::Base.connection
        connection.execute("SET FOREIGN_KEY_CHECKS = 0 ;")
        begin
          connection.execute("DELETE FROM sla_cache_spents ;")
        ensure
          connection.execute("SET FOREIGN_KEY_CHECKS = 1 ;")
        end
      else
        ActiveRecord::Base.connection.execute("TRUNCATE sla_cache_spents CASCADE ; ")
      end
    else
      SlaCacheSpent.where(project: project.id).delete_all
    end
  end
    
end
