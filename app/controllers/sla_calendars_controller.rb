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

class SlaCalendarsController < ApplicationController

  unloadable if defined?(Rails) && !Rails.autoloaders.zeitwerk_enabled?

  accept_api_auth :index, :create, :show, :update, :destroy

  before_action :require_admin, except: [:show]
  before_action :authorize_global

  before_action :find_sla_calendar, only: [ :show, :edit, :update ]
  before_action :find_sla_calendars, only: [ :destroy, :context_menu ]

  before_action :authorize_global

  helper :sla_calendars
  helper :context_menus

  helper :queries
  include QueriesHelper

  helper Queries::SlaCalendarsQueriesHelper
  include Queries::SlaCalendarsQueriesHelper   

  def index
    retrieve_query(SlaCalendarQuery) 
    @entity_count = @query.sla_calendars.count
    @entity_pages = Paginator.new @entity_count, per_page_option, params['page']
    @entities = @query.sla_calendars(offset: @entity_pages.offset, limit: @entity_pages.per_page) 
    respond_to do |format|
      format.html { }
      format.api { @offset, @limit = api_offset_and_limit }
    end    
  end

  def new
    @sla_calendar = SlaCalendar.new
    @sla_calendar.safe_attributes = params[:sla_calendar]
  end

  def create
    @sla_calendar = SlaCalendar.new()
    @sla_calendar.safe_attributes = params[:sla_calendar]
    if @sla_calendar.save && @sla_calendar.update(sla_calendar_params) && sla_schedules_overlapless
      respond_to do |format|
        format.html do
          flash[:notice] = l("sla_label.sla_calendar.notice_successful_create",
            :id => view_context.link_to("##{@sla_calendar.id}", sla_calendar_path(@sla_calendar), :title => @sla_calendar.name)
          )
          redirect_back_or_default sla_calendars_path
        end
        format.api do
          render :action => 'show', :status => :created,
            :location => sla_calendar_url(@sla_calendar)
        end
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.api { render_validation_errors(@sla_calendar) }
      end
    end
  end

  def update
    @sla_calendar.safe_attributes = params[:sla_calendar]
    if @sla_calendar.save && @sla_calendar.update(sla_calendar_params) && sla_schedules_overlapless
      respond_to do |format|
        format.html do
          flash[:notice] = l("sla_label.sla_calendar.notice_successful_update",
            :id => view_context.link_to("##{@sla_calendar.id}", sla_calendar_path(@sla_calendar), :title => @sla_calendar.name)
          )
          redirect_back_or_default sla_calendars_path
        end
        format.api { render_api_ok }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
        format.api { render_validation_errors(@sla_calendar) }
      end
    end
  end

  def destroy
    @sla_calendars.each do |sla_calendar|
      begin
        sla_calendar.reload.destroy
      rescue ::ActiveRecord::RecordNotFound
      end
    end
    respond_to do |format|
      format.html do
        flash[:notice] = l(:notice_successful_delete)
        redirect_back_or_default sla_calendars_path
      end
      format.api { render_api_ok }
    end    
  end

  def context_menu
    if @sla_calendars.size == 1
      @sla_calendar = @sla_calendars.first
    end
    can_show = @sla_calendars.detect{|c| !c.visible?}.nil?
    can_edit = @sla_calendars.detect{|c| !c.editable?}.nil?
    can_delete = @sla_calendars.detect{|c| !c.deletable?}.nil?
    @can = {show: can_show, edit: can_edit, delete: can_delete}
    @back = back_url
    @sla_calendar_ids, @safe_attributes, @selected = [], [], {}
    @sla_calendars.each do |e|
      @sla_calendar_ids << e.id
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

  def find_sla_calendar
    @sla_calendar = SlaCalendar.find(params[:id])
    raise Unauthorized unless @sla_calendar.visible?
    raise ActiveRecord::RecordNotFound if @sla_calendar.nil?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_sla_calendars
    params[:ids] = params[:id].nil? ? params[:ids] : [params[:id]] 
    @sla_calendars = SlaCalendar.find(params[:ids]).to_a
    @sla_calendar = @sla_calendars.first if @sla_calendars.count == 1
    raise Unauthorized unless @sla_calendars.all?(&:visible?)
    raise ActiveRecord::RecordNotFound if @sla_calendars.empty?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def sla_calendar_params
    params.require(:sla_calendar).permit(:name, sla_schedules_attributes: SlaSchedule.attribute_names.map(&:to_sym).push(:_destroy) )
  end   
  
  def sla_schedules_overlapless
    sla_schedules_nodestroy = params.to_unsafe_h[:sla_calendar][:sla_schedules_attributes]
    #Rails.logger.debug "==>> sla_calendar_overlapless ALL #{sla_schedules_nodestroy}"
    if ( !sla_schedules_nodestroy.nil? )
      sla_schedules_nodestroy = sla_schedules_nodestroy.select {|k,v| v[:_destroy]!=1 }
      #Rails.logger.debug "==>> sla_calendar_overlapless NoDestroy= #{sla_schedules_nodestroy}"
      if ( sla_schedules_nodestroy.count > 1 )
        sla_schedules_nodestroy.each do |key,value|
          #Rails.logger.debug "==>> sla_calendar_overlapless TEST key=#{key} value=#{value}"
          start_time = sla_schedules_nodestroy.select {|k,v| key!=k && value[:dow]==v[:dow] && v[:start_time].delete('^0-9')<=value[:start_time].delete('^0-9') && value[:start_time].delete('^0-9')<=v[:end_time].delete('^0-9') }
          #Rails.logger.debug "==>> sla_calendar_overlapless START #{start_time}"
          if start_time.count > 0
            @sla_calendar.errors.add(:base,l('sla_label.sla_schedule.overlaps'))
            return false
          end
          end_time = sla_schedules_nodestroy.select {|k,v| key!=k && value[:dow]==v[:dow] && v[:start_time].delete('^0-9')<=value[:end_time].delete('^0-9') && value[:end_time].delete('^0-9')<=v[:end_time].delete('^0-9') }
          #Rails.logger.debug "==>> sla_calendar_overlapless END #{end_time}"
          if end_time.count > 0
            @sla_calendar.errors.add(:base,l('sla_label.sla_schedule.overlaps'))
            return false
          end
        end
      end
    end
    true
  end

  def retrieve_default_query(use_session)
    return if params[:query_id].present?
    return if api_request?
    return if params[:set_filter]

    if params[:without_default].present?
      params[:set_filter] = 1
      return
    end
    if !params[:set_filter] && use_session && session[:sla_calendar_query]
      query_id = session[:sla_calendar_query].values_at(:id)
      return if SlaCalendarQuery.where(id: query_id).exists?
    end
    if default_query = SlaCalendarQuery.default()
      params[:query_id] = default_query.id
    end
  end    

  # Returns the SlaCalendarQuery scope for index and report actions
  def sla_calendar_scope(options={})
    @query.results_scope(options)
  end

  def retrieve_sla_calendar_query
    retrieve_query(SlaCalendarQuery, false, :defaults => @default_columns_names)
  end

  def query_error(exception)
    session.delete(:sla_calendar_query)
    super
  end  

end