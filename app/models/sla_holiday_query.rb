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

class SlaHolidayQuery < Query

  unloadable if defined?(Rails) && !Rails.autoloaders.zeitwerk_enabled?
  
  self.queried_class = SlaHoliday

  def initialize_available_filters
    add_available_filter 'name', type: :string
    add_available_filter 'date', type: :date
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = []
    @available_columns << QueryColumn.new(:id, :sortable => "#{SlaHoliday.table_name}.id", :default_order => nil, :groupable => false)
    @available_columns << QueryColumn.new(:name, :sortable => "#{SlaHoliday.table_name}.name", :default_order => nil, :groupable => true)
    @available_columns << QueryColumn.new(:date, :sortable => "#{SlaHoliday.table_name}.date", :default_order => :desc, :groupable => false)
    @available_columns
  end

  def initialize(attributes=nil, *args)
    super attributes
    self.filters ||= {
      # TODO : filter not apply on first time
      "date" => { :operator => "y", :values => [] } 
    }
  end

  def default_columns_names
    super.presence || [
      "name",
      "date"
    ].flat_map{|c| [c.to_s, c.to_sym]}
  end
  
  def sla_holidays(options={})
    order_option = [group_by_sort_order, (options[:order] || sort_clause)].flatten.reject(&:blank?)

    scope = base_scope.
        includes(((options[:include] || [])).uniq).
        where(options[:conditions]).
        order(order_option).
        joins(joins_for_order_statement(order_option.join(','))).
        limit(options[:limit]).
        offset(options[:offset])
    sla_holidays = scope.to_a
    sla_holidays
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def default_sort_criteria
    [['date', 'desc']]
  end
  
  # For Query Class
  def base_scope
    self.queried_class.visible.where(statement)
  end


end