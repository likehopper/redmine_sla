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

class Queries::SlaCalendarHolidayQuery < Query

  self.queried_class = SlaCalendarHoliday

  def initialize_available_filters
    add_available_filter 'sla_calendar_id', :type => :list, :values => lambda {all_sla_calendar_values}
    add_available_filter 'sla_holiday_id', :type => :list, :values => lambda {all_sla_holiday_values}
    add_available_filter 'match', :type => :list, :values => [[l(:general_text_yes), "1"], [l(:general_text_no), "0"]]
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = []
    group = l("label_filter_group_#{self.class.name.underscore}")

    @available_columns << QueryColumn.new(:sla_calendar, :sortable => nil, :default_order => nil, :groupable => false)
    @available_columns << QueryColumn.new(:sla_holiday, :sortable => nil, :default_order => nil, :groupable => false)
    @available_columns << QueryColumn.new(:match, :sortable => nil, :default_order => nil, :groupable => false)
    @available_columns
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
      "sla_calendar",
      "sla_holiday",
      "match"
    ].flat_map{|c| [c.to_s, c.to_sym]}
  end
  
  def sla_calendar_holidays(options={})
    order_option = [group_by_sort_order, (options[:order] || sort_clause)].flatten.reject(&:blank?)

    scope = SlaCalendarHoliday.visible.
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

    sla_calendar_holidays = scope.to_a

    sla_calendar_holidays
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def all_sla_calendar_values
    return @all_sla_calendar_values if @all_sla_calendar_values

    values ||= []
    SlaCalendar.pluck(:name,:id).map { |name,id|
      values << [name.to_s,id.to_s]
    }
    @all_sla_calendar_values = values
  end

  def all_sla_holiday_values
    return @all_sla_holiday_values if @all_sla_holiday_values

    values ||= []
    SlaHoliday.pluck(:name,:id).map { |name,id|
      values << [name.to_s,id.to_s]
    }
    @all_sla_holiday_values = values
  end  

end