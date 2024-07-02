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

class SlaCacheSpentQuery < Query

  unloadable
  
  self.queried_class = SlaCacheSpent
  self.view_permission = :view_sla

  def initialize_available_filters
    add_available_filter 'project_id', type: :list, :name => :project, values: lambda {project_values}
    add_available_filter 'issue_id', type: :integer, :name => :issue
    add_available_filter 'sla_level_id', :type => :list, :values => lambda {all_sla_level_values}
    add_available_filter 'sla_type_id', type: :list, values: lambda {all_sla_type_values}
    add_available_filter 'created_on', :type => :date_past if User.current.admin?
    add_available_filter 'updated_on', :type => :date_past
    add_available_filter 'spent', :type => :integer
    add_available_filter "issue.tracker_id", :type => :list_with_history, :name => l("label_attribute_of_issue",:name => l(:field_tracker)), :values => lambda {trackers.map {|t| [t.name, t.id.to_s]}}
    add_available_filter "issue.status_id", :type => :list_status, :name => l("label_attribute_of_issue", :name => l(:field_status)), :values => lambda {issue_statuses_values}
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = []
    @available_columns << QueryColumn.new(:id, :sortable => "#{SlaCacheSpent.table_name}.id", :default_order => nil, :groupable => false )
    @available_columns << QueryColumn.new(:project, :sortable => "#{Project.table_name}.name", :default_order => nil, :groupable => true)
    @available_columns << QueryColumn.new(:issue, :sortable => "#{Issue.table_name}.id", :default_order => :desc, :groupable => true)
    sla_level_columns = QueryColumn.new(:sla_level, :sortable => "( SELECT DISTINCT #{SlaLevel.table_name}.name FROM #{SlaLevel.table_name} WHERE ( #{SlaCache.table_name}.sla_level_id = #{SlaLevel.table_name}.id ) )", :default_order => nil, :groupable => true )
    def sla_level_columns.group_by_statement
      self.sortable
    end
    @available_columns << sla_level_columns
    @available_columns << QueryColumn.new(:sla_type, :sortable => "#{SlaType.table_name}.name", :default_order => nil, :groupable => true )
    @available_columns << QueryColumn.new(:spent, :sortable => "#{SlaCacheSpent.table_name}.spent", :default_order => nil, :groupable => false )
    @available_columns << QueryColumn.new(:created_on, :sortable => "#{SlaCache.table_name}.created_on", :default_order => nil, :groupable => false ) if User.current.admin?
    @available_columns << QueryColumn.new(:updated_on, :sortable => "#{SlaCacheSpent.table_name}.updated_on", :default_order => nil, :groupable => false )
    @available_columns << QueryAssociationColumn.new(:issue, :status, :caption => :field_status, :sortable => "#{IssueStatus.table_name}.position" )
    @available_columns << QueryAssociationColumn.new(:issue, :tracker, :caption => :field_tracker, :sortable => "#{Tracker.table_name}.position" )    
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
      'issue.status_id' => {:operator => "o", :values => [""]}
    }
  end

  def default_columns_names
    super.presence || [
      "issue",
      "sla_type",
      "spent",
      "updated_on",
    ].flat_map{|c| [c.to_s, c.to_sym]}
  end

  def sla_cache_spents(options={})
    order_option = [group_by_sort_order, (options[:order] || sort_clause)].flatten.reject(&:blank?)

    scope = base_scope.
        includes(((options[:include] || [])).uniq).
        where(options[:conditions]).
        order(order_option).
        joins(joins_for_order_statement(order_option.join(','))).
        limit(options[:limit]).
        offset(options[:offset])

    sla_cache_spents = scope.to_a
    sla_cache_spents
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

   # For Query Class
   def base_scope
    self.queried_class.visible.
    joins(:sla_cache,:project,:issue).
    where(statement)
  end

  def results_scope(options={})
    order_option = [group_by_sort_order, (options[:order] || sort_clause)].flatten.reject(&:blank?)

    order_option << "#{self.queried_class.table_name}.id ASC"
    base_scope.
      order(order_option).
      joins(joins_for_order_statement(order_option.join(',')))
  end

  def sql_for_sla_level_id_field(field, operator, value)
    sql_for_field("sla_level_id", operator, value, SlaCache.table_name, "sla_level_id")
  end 

  def sql_for_issue_id_field(field, operator, value)
    self.class.queried_class = Issue
    sql_for_field("issue_id", operator, value, Issue.table_name, "id")
  ensure
    self.class.queried_class = SlaCacheSpent
  end  

  def sql_for_issue_tracker_id_field(field, operator, value)
    self.class.queried_class = Issue
    sql_for_field("tracker_id", operator, value, Issue.table_name, "tracker_id")
  ensure
    self.class.queried_class = SlaCacheSpent
  end

  def sql_for_issue_status_id_field(field, operator, value)
    self.class.queried_class = Issue
    sql_for_field("status_id", operator, value, Issue.table_name, "status_id") # .gsub('sla_caches', 'issues')
  ensure
    self.class.queried_class = SlaCacheSpent
  end

  def joins_for_order_statement(order_options)
    joins = [super]

    if order_options
      if order_options.include?('issue_statuses')
        joins << "LEFT OUTER JOIN #{IssueStatus.table_name} ON #{IssueStatus.table_name}.id = #{Issue.table_name}.status_id"
      end
      if order_options.include?('trackers')
        joins << "LEFT OUTER JOIN #{Tracker.table_name} ON #{Tracker.table_name}.id = #{Issue.table_name}.tracker_id"
      end
    end

    joins.compact!
    joins.any? ? joins.join(' ') : nil
  end

  def all_sla_cache_spent_values
    return @all_sla_cache_spent_values if @all_sla_cache_spent_values

    values ||= []
    SlaCache.pluck(:subject,:id).map { |subject,id|
      values << [subject.to_s,id.to_s]
    }
    @all_sla_cache_spent_values = values
  end

  def all_sla_type_values
    return @all_sla_type_values if @all_sla_type_values

    values ||= []
    SlaType.pluck(:name,:id).map { |name,id|
      values << [name.to_s,id.to_s]
    }
    @all_sla_type_values = values
  end

  def all_sla_level_values
    return @all_sla_level_values if @all_sla_level_values

    values ||= []
    SlaLevel.pluck(:name,:id).map { |name,id|
      values << [name.to_s,id.to_s]
    }
    @all_sla_level_values = values
  end  

end