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

class SlaCalendarQuery < Query

  unloadable
  
  self.queried_class = SlaCalendar

  def initialize_available_filters
    add_available_filter 'name', type: :string
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = []
    @available_columns << QueryColumn.new(:id, :sortable => "#{SlaCalendar.table_name}.id", :default_order => :asc, :groupable => false)
    @available_columns << QueryColumn.new(:name, :sortable => "#{SlaCalendar.table_name}.name", :default_order => :asc, :groupable => false)
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
      "name"
    ].flat_map{|c| [c.to_s, c.to_sym]}
  end
  
  def sla_calendars(options={})
    order_option = [group_by_sort_order, (options[:order] || sort_clause)].flatten.reject(&:blank?)

    scope = self.queried_class.visible.where(statement).
        includes(((options[:include] || [])).uniq).
        where(options[:conditions]).
        order(order_option).
        joins(joins_for_order_statement(order_option.join(','))).
        limit(options[:limit]).
        offset(options[:offset])

    sla_calendars = scope.to_a
    sla_calendars
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  # For Query Class
  def base_scope
    self.queried_class.visible.where(statement)
  end

end