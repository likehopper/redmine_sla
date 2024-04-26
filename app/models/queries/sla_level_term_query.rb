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

class Queries::SlaLevelTermQuery < Query

  unloadable
  
  self.queried_class = SlaLevelTerm

  def initialize_available_filters
    add_available_filter 'sla_level_id', :type => :list, :values => lambda {all_sla_level_values}
    add_available_filter 'sla_type_id', type: :list, :values => lambda {all_sla_type_values}
    add_available_filter 'priority_id', :type => :list, :values => IssuePriority.all.collect{|s| [s.name, s.id.to_s] }
    add_available_filter 'term', type: :integer    
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = []
    group = l("label_filter_group_#{self.class.name.underscore}")

    @available_columns << QueryColumn.new(:sla_level, :sortable => "#{SlaLevel.table_name}.name", :default_order => :asc, :groupable => true)
    @available_columns << QueryColumn.new(:sla_type, :sortable => "#{SlaType.table_name}.name", :default_order => :asc, :groupable => true)
    @available_columns << QueryColumn.new(:priority, :sortable => "#{IssuePriority.table_name}.position", :default_order => :asc, :groupable => true)
    @available_columns << QueryColumn.new(:term, :sortable => "#{SlaLevelTerm.table_name}.term", :default_order => nil, :groupable => false)
    @available_columns
  end

  def initialize(attributes=nil, *args)
    super attributes
    self.filters ||= {
    #  "sla_level_id" => {:operator => "*", :values => []},
    #  "sla_type_id" => {:operator => "*", :values => []},
    #  "priority_id" => {:operator => "*", :values => []},
    #  "term" => {:operator => "*", :values => []}
    }
  end

  def default_columns_names
    super.presence || [
      "sla_level",
      "sla_type",
      "priority",
      "term"
    ].flat_map{|c| [c.to_s, c.to_sym]}
  end
  
  def sla_level_terms(options={})
    order_option = [group_by_sort_order, (options[:order] || sort_clause)].flatten.reject(&:blank?)

    scope = base_scope.
        includes(((options[:include] || [])).uniq).
        where(options[:conditions]).
        order(order_option).
        joins(joins_for_order_statement(order_option.join(','))).
        limit(options[:limit]).
        offset(options[:offset])

    sla_level_terms = scope.to_a
    sla_level_terms
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  # For Query Class
  def base_scope
    self.queried_class.visible.where(statement)
  end  

  # TODO: not yes in use
  def all_sla_level_values
    return @all_sla_level_values if @all_sla_level_values

    values ||= []
    SlaLevel.pluck(:name,:id).map { |name,id|
      values << [name.to_s,id.to_s]
    }
    @all_sla_level_values = values
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