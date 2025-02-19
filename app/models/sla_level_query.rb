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

class SlaLevelQuery < Query

  unloadable if defined?(Rails) && !Rails.autoloaders.zeitwerk_enabled?
  
  self.queried_class = SlaLevel

  def initialize_available_filters
    add_available_filter 'name', type: :string
    add_available_filter 'sla_id', type: :list, :values => lambda {all_sla_values}
    add_available_filter 'sla_calendar_id', :type => :list, :values => lambda {all_sla_calendar_values}
    add_available_filter 'custom_field_id', :type => :list, :values => lambda {all_sla_custom_fields_values}
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = []
    @available_columns << QueryColumn.new(:id, :sortable => "#{SlaLevel.table_name}.id", :default_order => :asc, :groupable => false)
    @available_columns << QueryColumn.new(:name, :sortable => "#{SlaLevel.table_name}.name", :default_order => :asc, :groupable => false)
    @available_columns << QueryColumn.new(:sla, :sortable => "#{Sla.table_name}.name", :default_order => :asc, :groupable => true)
    @available_columns << QueryColumn.new(:sla_calendar, :sortable => "#{SlaCalendar.table_name}.name", :default_order => :asc, :groupable => true)
    @available_columns << QueryColumn.new(:custom_field, :sortable => "#{CustomField.table_name}.name", :default_order => :asc, :groupable => true)
    @available_columns
  end

  def initialize(attributes=nil, *args)
    super attributes
    self.filters ||= {
    #  "name" => {:operator => "*", :values => []},
    #  "sla_id" => {:operator => "*", :values => []},
    #  "sla_calendar_id" => {:operator => "*", :values => []}
    }
  end

  def default_columns_names
    super.presence || [
      "name",
      "sla",
      "sla_calendar",
      "custom_field"
    ].flat_map{|c| [c.to_s, c.to_sym]}
  end
  
  def sla_levels(options={})
    order_option = [group_by_sort_order, (options[:order] || sort_clause)].flatten.reject(&:blank?)

    scope = base_scope.
        includes(((options[:include] || [])).uniq).
        where(options[:conditions]).
        order(order_option).
        joins(joins_for_order_statement(order_option.join(','))).
        limit(options[:limit]).
        offset(options[:offset])

    sla_levels = scope.to_a
    sla_levels
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  # For Query Class
  def base_scope
    self.queried_class.visible.where(statement)
  end  

  def all_sla_values
    return @all_sla_values if @all_sla_values

    values ||= []
    Sla.pluck(:name,:id).map { |name,id|
      values << [name.to_s,id.to_s]
    }
    @all_sla_values = values
  end

  def all_sla_calendar_values
    return @all_sla_calendar_values if @all_sla_calendar_values

    values ||= []
    SlaCalendar.pluck(:name,:id).map { |name,id|
      values << [name.to_s,id.to_s]
    }
    @all_sla_calendar_values = values
  end

  def all_sla_custom_fields_values
    return @all_sla_custom_fields_values if @all_sla_custom_fields_values

    values ||= []
    SlaCustomField.pluck(:name,:id).map { |name,id|
      values << [name.to_s,id.to_s]
    }
    @all_sla_custom_fields_values = values
  end

end