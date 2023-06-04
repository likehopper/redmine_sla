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

class Queries::SlaStatusQuery < Query

  self.queried_class = SlaStatus

  def initialize_available_filters
    add_available_filter 'sla_type_id', type: :list, :values => lambda {all_sla_types_values}
    add_available_filter 'status_id', :type => :list_status, :values => lambda {issue_statuses_values}
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = []
    group = l("label_filter_group_#{self.class.name.underscore}")

    @available_columns << QueryColumn.new(:sla_type, :sortable => nil, :default_order => nil, :groupable => false )
    @available_columns << QueryColumn.new(:status, :sortable => nil, :default_order => nil, :groupable => false )
    @available_columns
  end

  def initialize(attributes=nil, *args)
    super attributes
    self.filters ||= {
    #  "sla_type_id" => {:operator => "*", :values => []},
    #  "status_id" => {:operator => "*", :values => []}
    }
  end

  def default_columns_names
    super.presence || [
      "sla_type",
      "status"
    ].flat_map{|c| [c.to_s, c.to_sym]}
  end
  
  def sla_statuses(options={})
    order_option = [group_by_sort_order, (options[:order] || sort_clause)].flatten.reject(&:blank?)

    scope = SlaStatus.visible.
        where(statement).
        includes(((options[:include] || [])).uniq).
        where(options[:conditions]).
        order(order_option).
        joins(joins_for_order_statement(order_option.join(','))).
        limit(options[:limit]).
        offset(options[:offset])

    if has_custom_field_column?
      scope = scope.preload(:custom_values)
    end

    sla_statuses = scope.to_a

    sla_statuses
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def all_sla_types_values
    return @all_sla_types_values if @all_sla_types_values

    values ||= []
    SlaType.pluck(:name,:id).map { |name,id|
      values << [name.to_s,id.to_s]
    }
    @all_sla_types_values = values
  end

end