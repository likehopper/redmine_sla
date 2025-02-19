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

class SlaSchedulesController < ApplicationController

  unloadable if defined?(Rails) && !Rails.autoloaders.zeitwerk_enabled?

  accept_api_auth :index, :create, :show, :update, :destroy
  
  before_action :require_admin
  before_action :authorize_global

  before_action :find_sla_schedule, only: [ :show, :edit, :update ]
  before_action :find_sla_schedules, only: [ :destroy, :context_menu ]
  #before_action :setup_sla_schedules

  helper :sla_schedules
  helper :context_menus

  helper :queries
  include QueriesHelper

  helper Queries::SlaSchedulesQueriesHelper
  include Queries::SlaSchedulesQueriesHelper 

  def index
    retrieve_query(SlaScheduleQuery) 
    @entity_count = @query.sla_schedules.count
    @entity_pages = Paginator.new @entity_count, per_page_option, params['page']
    @entities = @query.sla_schedules(offset: @entity_pages.offset, limit: @entity_pages.per_page)
    respond_to do |format|
      format.html do
      end
      format.api do
        @offset, @limit = api_offset_and_limit
      end
    end      
  end
  
  def new
    @sla_schedule = SlaSchedule.new
    @sla_schedule.safe_attributes = params[:sla_schedule]
  end

  def create
    @sla_schedule = SlaSchedule.new
    @sla_schedule.safe_attributes = params[:sla_schedule]
    @sla_schedule.start_time = @sla_schedule.start_time.strftime("%H:%M:00")
    @sla_schedule.end_time = @sla_schedule.end_time.strftime("%H:%M:59")
    if @sla_schedule.save
      respond_to do |format|
        format.html do
          flash[:notice] = l(:notice_successful_create)
          redirect_back_or_default sla_schedules_path
        end
        format.api do
          render :action => 'show', :status => :created,
            :location => sla_schedule_url(@sla_schedule)
        end
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.api { render_validation_errors(@sla_schedule) }
      end
    end
  end

  def update
    @sla_schedule.safe_attributes = params[:sla_schedule]
    @sla_schedule.start_time = @sla_schedule.start_time.strftime("%H:%M:00")
    @sla_schedule.end_time = @sla_schedule.end_time.strftime("%H:%M:59")
    if @sla_schedule.save
      respond_to do |format|
        format.html do
          flash[:notice] = l(:notice_successful_update)
          redirect_back_or_default sla_schedules_path
        end
        format.api { render_api_ok }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
        format.api { render_validation_errors(@sla_schedule) }
      end
    end

  end

  def destroy
    @sla_schedules.each do |sla_schedule|
      begin
        sla_schedule.reload.destroy
      rescue ::ActiveRecord::RecordNotFound
      end
    end
    respond_to do |format|
      format.html do
        flash[:notice] = l(:notice_successful_delete)
        redirect_back_or_default sla_schedules_path
      end
      format.api { render_api_ok }
    end       
  end

  def context_menu
    if @sla_schedules.size == 1
      @sla_schedule = @sla_schedules.first
    end
    can_show = @sla_schedules.detect{|c| !c.visible?}.nil?
    can_edit = @sla_schedules.detect{|c| !c.editable?}.nil?
    can_delete = @sla_schedules.detect{|c| !c.deletable?}.nil?
    @can = {show: can_show, edit: can_edit, delete: can_delete}
    @back = back_url
    @sla_schedule_ids, @safe_attributes, @selected = [], [], {}
    @sla_schedules.each do |e|
      @sla_schedule_ids << e.id
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

  def find_sla_schedule
    @sla_schedule = SlaSchedule.find(params[:id])
    raise Unauthorized unless @sla_schedule.visible?
    raise ActiveRecord::RecordNotFound if @sla_schedule.nil?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_sla_schedules
    params[:ids] = params[:id].nil? ? params[:ids] : [params[:id]] 
    @sla_schedules = SlaSchedule.find(params[:ids]).to_a
    @sla_schedule = @sla_schedules.first if @sla_schedules.count == 1
    raise Unauthorized unless @sla_schedules.all?(&:visible?)
    raise ActiveRecord::RecordNotFound if @sla_schedules.empty?
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
    if !params[:set_filter] && use_session && session[:sla_schedule_query]
      query_id = session[:sla_schedule_query].values_at(:id)
      return if SlaScheduleQuery.where(id: query_id).exists?
    end
    if default_query = SlaScheduleQuery.default()
      params[:query_id] = default_query.id
    end
  end    

  # Returns the SlaScheduleQuery scope for index and report actions
  def sla_schedule_scope(options={})
    @query.results_scope(options)
  end

  def retrieve_sla_schedule_query
    retrieve_query(SlaScheduleQuery, false, :defaults => @default_columns_names)
  end

  def query_error(exception)
    session.delete(:sla_schedule_query)
    super
  end

  # https://dev.to/pezza/dynamic-nested-forms-with-turbo-3786
  #def setup_sla_schedules
  #  @sla_schedules = SlaSchedules.new(sla_schedules: [SlaSchedule.new])
  #end

end