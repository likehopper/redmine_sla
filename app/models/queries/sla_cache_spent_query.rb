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

class Queries::SlaCacheSpentQuery < Query

  unloadable
  
  self.queried_class = SlaCacheSpent

  def initialize_available_filters
    add_available_filter 'project_id', type: :list, :name => :project, values: lambda {project_values}
    add_available_filter 'issue_id', type: :integer, :name => :issue
    add_available_filter 'sla_type_id', type: :list, values: lambda {all_sla_type_values}
    add_available_filter 'updated_on', :type => :date_past
    add_available_filter 'spent', :type => :integer
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = []
    @available_columns << QueryColumn.new(:project, :sortable => "#{Project.table_name}.name", :default_order => nil, :groupable => true)
    @available_columns << QueryColumn.new(:issue, :sortable => "#{Issue.table_name}.id", :default_order => :desc, :groupable => true)
    @available_columns << QueryColumn.new(:sla_type, :sortable => "#{SlaType.table_name}.name", :default_order => nil, :groupable => true )
    @available_columns << QueryColumn.new(:spent, :sortable => "#{SlaCacheSpent.table_name}.spent", :default_order => nil, :groupable => false )
    @available_columns << QueryColumn.new(:updated_on, :sortable => "#{SlaCacheSpent.table_name}.updated_on", :default_order => nil, :groupable => false )
    @available_columns
  end

  def initialize(attributes=nil, *args)
    super attributes
    self.filters ||= {
    #  "name" => {:operator => "*", :values => []}
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
  
  def sql_for_issue_project_id_field(field, operator, value)
    sql_for_field("project_id", operator, value, Issue.table_name, "project_id")
  end

  def sql_for_sla_cache_issue_id_field(field, operator, value)
    sql_for_field("issue_id", operator, value, SlaCache.table_name, "issue_id")
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
    self.queried_class.visible.where(statement)
  end

  # TODO: not yes in use
  def all_sla_cache_values
    return @all_sla_cache_values if @all_sla_cache_values

    values ||= []
    SlaCache.pluck(:subject,:id).map { |subject,id|
      values << [subject.to_s,id.to_s]
    }
    @all_sla_cache_values = values
  end

  # TODO: not yes in use
  def all_sla_type_values
    return @all_sla_type_values if @all_sla_type_values

    values ||= []
    SlaType.pluck(:name,:id).map { |name,id|
      values << [name.to_s,id.to_s]
    }
    @all_sla_type_values = values
  end

end