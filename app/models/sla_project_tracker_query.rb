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

class SlaProjectTrackerQuery < Query

  unloadable
  
  self.queried_class = SlaProjectTracker
  self.view_permission = :manage_sla

  def initialize_available_filters
    add_available_filter 'project_id', type: :list, :name => :project, values: lambda {project_values} if project.nil?
    add_available_filter 'tracker_id', type: :list, :values => Tracker.all.collect{|s| [s.name, s.id.to_s] }
    add_available_filter 'sla_id', type: :list, :values => Sla.all.collect{|s| [s.name, s.id.to_s] }
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = []
    @available_columns << QueryColumn.new(:id, :sortable => "#{SlaProjectTracker.table_name}.id", :default_order => :asc, :groupable => false )
    @available_columns << QueryColumn.new(:project, :sortable => "#{Project.table_name}.name", :default_order => :asc, :groupable => (project.nil??true:false) )
    @available_columns << QueryColumn.new(:tracker, :sortable => "#{Tracker.table_name}.position", :default_order => :asc, :groupable => true)
    @available_columns << QueryColumn.new(:sla, :sortable => "#{Sla.table_name}.name", :default_order => :asc, :groupable => true)
    @available_columns
  end

  def self.default(project: nil, user: User.current)
    # user default
    if user&.logged? && (query_id = user.pref.default_issue_query).present?
      query = find_by(id: query_id)
      return query if query&.visible?(user)
    end

    # project default
    query = project&.default_issue_query
    return query if query&.visibility == VISIBILITY_PUBLIC

    nil
  end

  def initialize(attributes=nil, *args)
    super attributes
    self.filters ||= { 
    #  "sla_calendar_id" => {:operator => "*", :values => []}      
    #  "sla_holiday_id" => {:operator => "*", :values => []},
    #  "match" => {:operator => "*", :values => []} 
    }
  end

  def default_columns_names
    super.presence || [
      "project",
      "tracker",
      "sla"
    ].flat_map{|c| [c.to_s, c.to_sym]}
  end

  # For Query Class
  def base_scope
    # self.queried_class.visible.where(statement)
    self.queried_class.visible.
      joins(:project).
      where(statement)
  end
  
  def sla_project_trackers(options={})
    order_option = [group_by_sort_order, (options[:order] || sort_clause)].flatten.reject(&:blank?)

    scope = self.queried_class.visible.where(statement).
        includes(((options[:include] || [])).uniq).
        where(options[:conditions]).
        order(order_option).
        joins(joins_for_order_statement(order_option.join(','))).
        limit(options[:limit]).
        offset(options[:offset])

    sla_project_trackers = scope.to_a
    sla_project_trackers
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  # For Query Class
  def base_scope
    self.queried_class.visible.
    joins(:sla,:tracker,:project).
    where(statement)
  end  

end