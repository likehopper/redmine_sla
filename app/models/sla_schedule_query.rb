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

class SlaScheduleQuery < Query

  self.queried_class = SlaSchedule

  def initialize_available_filters
    add_available_filter 'sla_calendar_id', :type => :list, :values => lambda {all_sla_calendar_values}
    add_available_filter 'dow', type: :list, :values => I18n.t('date.day_names').map.with_index{|name,id| [name.to_s, id.to_s] } 
    # TODO : type time need to override query class ;(
    # add_available_filter 'start_time', type: :time
    # add_available_filter 'end_time', type: :time
    add_available_filter 'match', :type => :list, :values => [[l(:general_text_yes), "1"], [l(:general_text_no), "0"]]
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = []
    @available_columns << QueryColumn.new(:id, :sortable => "#{SlaSchedule.table_name}.id", :default_order => nil, :groupable => false )
    @available_columns << QueryColumn.new(:sla_calendar, :sortable => "#{SlaCalendar.table_name}.name", :default_order => :asc, :groupable => true)
    @available_columns << QueryColumn.new(:dow, :sortable => "#{SlaSchedule.table_name}.dow", :default_order => nil, :groupable => true )
    # TODO : type time need to override query class ;(
    #@available_columns << QueryColumn.new(:start_time, :sortable => "#{SlaSchedule.table_name}.start_time", :default_order => :desc, :groupable => false )
    #@available_columns << QueryColumn.new(:end_time, :sortable => "#{SlaSchedule.table_name}.end_time", :default_order => :desc, :groupable => false )
    @available_columns << QueryColumn.new(:match, :sortable => "#{SlaSchedule.table_name}.match", :default_order => nil, :groupableupable => true )
    @available_columns
  end

  def initialize(attributes=nil, *args)
    super attributes
    self.filters ||= {
    #  "sla_calendar_id" => {:operator => "*", :values => []},
    #  "dow" => {:operator => "*", :values => []},
    #  "start_time" => {:operator => "*", :values => []},            
    #  "end_time" => {:operator => "*", :values => []},
    #  "match" => {:operator => "*", :values => []}
    }
  end

  def default_columns_names
    super.presence || [
      "sla_calendar",
      "dow",
      "start_time",
      "end_time",
      "match"
    ].flat_map{|c| [c.to_s, c.to_sym]}
  end
  
  def sla_schedules(options={})
    order_option = [group_by_sort_order, (options[:order] || sort_clause)].flatten.reject(&:blank?)

    scope = self.queried_class.visible.where(statement).
        includes(((options[:include] || [])).uniq).
        where(options[:conditions]).
        order(order_option).
        joins(joins_for_order_statement(order_option.join(','))).
        limit(options[:limit]).
        offset(options[:offset])

    sla_schedules = scope.to_a
    sla_schedules
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  # For Query Class
  def base_scope
    self.queried_class.visible.where(statement)
  end  

  def all_sla_calendar_values
    return @all_sla_calendar_values if @all_sla_calendar_values

    values ||= []
    SlaCalendar.pluck(:name,:id).map { |name,id|
      values << [name.to_s,id.to_s]
    }
    @all_sla_calendar_values = values
  end

end