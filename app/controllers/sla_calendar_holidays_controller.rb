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

class SlaCalendarHolidaysController < ApplicationController

  unloadable if defined?(Rails) && !Rails.autoloaders.zeitwerk_enabled?

  accept_api_auth :index, :create, :show, :update, :destroy
  before_action :require_admin
  before_action :authorize_global

  before_action :find_sla_calendar_holiday, only: [ :show, :edit, :update ]
  before_action :find_sla_calendar_holidays, only: [ :destroy, :context_menu ]

  helper :sla_calendar_holidays
  helper :context_menus

  helper :queries
  include QueriesHelper

  helper Queries::SlaCalendarHolidaysQueriesHelper
  include Queries::SlaCalendarHolidaysQueriesHelper  

  def index
    retrieve_query(SlaCalendarHolidayQuery) 
    @entity_count = @query.sla_calendar_holidays.count
    @entity_pages = Paginator.new @entity_count, per_page_option, params['page']
    @entities = @query.sla_calendar_holidays(offset: @entity_pages.offset, limit: @entity_pages.per_page) 
    respond_to do |format|
      format.html do end
      format.api do @offset, @limit = api_offset_and_limit end
    end    
  end

  def new
    @sla_calendar_holiday = SlaCalendarHoliday.new
    @sla_calendar_holiday.safe_attributes = params[:sla_calendar_holiday]
  end

  def create
    @sla_calendar_holiday = SlaCalendarHoliday.new
    @sla_calendar_holiday.safe_attributes = params[:sla_calendar_holiday]
    if @sla_calendar_holiday.save
      respond_to do |format|
        format.html do
          flash[:notice] = l(:notice_successful_create)
          redirect_back_or_default sla_calendar_holidays_path
        end
        format.api do
          render :action => 'show', :status => :created,
            :location => sla_calendar_holiday_url(@sla_calendar_holiday)
        end
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.api { render_validation_errors(@sla_calendar_holiday) }
      end
    end

  end

  def update
    @sla_calendar_holiday.safe_attributes = params[:sla_calendar_holiday]
    if @sla_calendar_holiday.save
      respond_to do |format|
        format.html do
          flash[:notice] = l(:notice_successful_update)
          redirect_back_or_default sla_calendar_holidays_path
        end
        format.api { render_api_ok }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
        format.api { render_validation_errors(@sla_calendar_holiday) }
      end
    end
  end

  def destroy
    @sla_calendar_holidays.each do |sla_calendar_holiday|
      begin
        sla_calendar_holiday.reload.destroy
      rescue ::ActiveRecord::RecordNotFound
      end
    end
    respond_to do |format|
      format.html do
        flash[:notice] = l(:notice_successful_delete)
        redirect_back_or_default sla_calendar_holidays_path
      end
      format.api { render_api_ok }
    end        
  end

  def context_menu
    if @sla_calendar_holidays.size == 1
      @sla_calendar_holiday = @sla_calendar_holidays.first
    end
    can_show = @sla_calendar_holidays.detect{|c| !c.visible?}.nil?
    can_edit = @sla_calendar_holidays.detect{|c| !c.editable?}.nil?
    can_delete = @sla_calendar_holidays.detect{|c| !c.deletable?}.nil?
    @can = {show: can_show, edit: can_edit, delete: can_delete}
    @back = back_url
    @sla_calendar_holiday_ids, @safe_attributes, @selected = [], [], {}
    @sla_calendar_holidays.each do |e|
      @sla_calendar_holiday_ids << e.id
      @safe_attributes.concat e.safe_attribute_names
      attributes = e.safe_attribute_names
      attributes.each do |c|
        column_name = c.to_sym
        if @selected.key? column_name
          @selected[column_name] = nil if @selected[column_name] != e.send(column_name)
        else
          @selected[column_name] = e.send(column_name)
        end
      end
    end
    @safe_attributes.uniq!
    render layout: false
  end

  private

  def find_sla_calendar_holiday
    @sla_calendar_holiday = SlaCalendarHoliday.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_sla_calendar_holidays
    @sla_calendar_holidays = SlaCalendarHoliday.visible.where(id: (params[:id]||params[:ids])).to_a
    raise ActiveRecord::RecordNotFound if @sla_calendar_holidays.empty?
    #raise Unauthorized unless @sla_calendar_holidays.all?(&:visible?)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def retrieve_default_query(use_session)
    return if params[:query_id].present?
    return if api_request?
    return if params[:set_filter]

    if params[:without_default].present?
      params[:set_filter] = 1
      return
    end
    if !params[:set_filter] && use_session && session[:sla_calendar_holiday_query]
      query_id = session[:sla_calendar_holiday_query].values_at(:id)
      return if SlaCalendarHolidayQuery.where(id: query_id).exists?
    end
    if default_query = SlaCalendarHolidayQuery.default()
      params[:query_id] = default_query.id
    end
  end   

  # Returns the SlaCalendarHolidayQuery scope for index and report actions
  def sla_calendar_holiday_scope(options={})
    @query.results_scope(options)
  end

  def retrieve_sla_calendar_holiday_query
    retrieve_query(SlaCalendarHolidayQuery, false, :defaults => @default_columns_names)
  end

  def query_error(exception)
    session.delete(:sla_calendar_holiday_query)
    super
  end    

end