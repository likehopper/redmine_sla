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

class Queries::SlaProjectTrackerQuery < Query

  self.queried_class = SlaProjectTracker

  def initialize_available_filters
    add_available_filter 'tracker_id', type: :list, :values => Tracker.all.collect{|s| [s.name, s.id.to_s] }
    add_available_filter 'sla_id', type: :list, :values => Sla.all.collect{|s| [s.name, s.id.to_s] }
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = []
    group = l("label_filter_group_#{self.class.name.underscore}")

    @available_columns << QueryColumn.new(:tracker, :sortable => nil, :default_order => nil, :groupable => false)
    @available_columns << QueryColumn.new(:sla, :sortable => nil, :default_order => nil, :groupable => false)
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
      "tracker",
      "sla"
    ].flat_map{|c| [c.to_s, c.to_sym]}
  end
  
  def sla_project_trackers(options={})
    order_option = [group_by_sort_order, (options[:order] || sort_clause)].flatten.reject(&:blank?)

    scope = SlaProjectTracker.visible.
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

    sla_project_trackers = scope.to_a

    sla_project_trackers

  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

end