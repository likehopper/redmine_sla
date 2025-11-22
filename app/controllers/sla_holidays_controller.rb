# frozen_string_literal: true

# File: redmine_sla/app/controllers/sla_holidays_controller.rb
# Purpose:
#   Manage SLA Holidays (generic non-working days that can be reused by
#   SLA calendars). This controller provides:
#     - listing and filtering via SlaHolidayQuery,
#     - creation, update and deletion,
#     - context menu support,
#     - API access for index/show/create/update/destroy.
#
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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
# ------------------------------------------------------------------------------

class SlaHolidaysController < ApplicationController

  accept_api_auth :index, :create, :show, :update, :destroy
  
  before_action :require_admin
  before_action :authorize_global

  before_action :find_sla_holiday,   only: [:show, :edit, :update]
  before_action :find_sla_holidays,  only: [:destroy, :context_menu]

  helper :sla_holidays
  helper :context_menus

  helper :queries
  include QueriesHelper

  helper Queries::SlaHolidaysQueriesHelper
  include Queries::SlaHolidaysQueriesHelper     

  # List SLA holidays via SlaHolidayQuery, with pagination.
  def index
    retrieve_query(SlaHolidayQuery) 
    @entity_count = @query.sla_holidays.count
    @entity_pages = Paginator.new @entity_count, per_page_option, params['page']
    @entities     = @query.sla_holidays(
      offset: @entity_pages.offset,
      limit:  @entity_pages.per_page
    )
    respond_to do |format|
      format.html do
      end
      format.api do
        @offset, @limit = api_offset_and_limit
      end
    end    
  end

  # Render form for a new SLA Holiday.
  def new
    @sla_holiday = SlaHoliday.new
    @sla_holiday.safe_attributes = params[:sla_holiday]
  end

  # Create a new SLA Holiday.
  def create
    @sla_holiday = SlaHoliday.new
    @sla_holiday.safe_attributes = params[:sla_holiday]
    if @sla_holiday.save
      respond_to do |format|
        format.html do
          flash[:notice] = l(
            "sla_label.sla_holiday.notice_successful_create",
            :id => view_context.link_to("##{@sla_holiday.id}", sla_holiday_path(@sla_holiday), :title => @sla_holiday.name)
          )
          redirect_back_or_default sla_holidays_path
        end
        format.api do
          render :action => 'show', :status => :created,
                 :location => sla_holiday_url(@sla_holiday)
        end
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.api  { render_validation_errors(@sla_holiday) }
      end
    end
  end

  # Update an existing SLA Holiday.
  def update
    @sla_holiday.safe_attributes = params[:sla_holiday]
    if @sla_holiday.save
      respond_to do |format|
        format.html do
          flash[:notice] = l(
            "sla_label.sla_holiday.notice_successful_update",
            :id => view_context.link_to("##{@sla_holiday.id}", sla_holiday_path(@sla_holiday), :title => @sla_holiday.name)
          )
          redirect_back_or_default sla_holidays_path
        end
        format.api { render_api_ok }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
        format.api  { render_validation_errors(@sla_holiday) }
      end
    end
  end

  # Destroy one or more SLA Holidays.
  def destroy
    @sla_holidays.each do |sla_holiday|
      begin
        sla_holiday.reload.destroy
      rescue ::ActiveRecord::RecordNotFound
      end
    end
    respond_to do |format|
      format.html do
        flash[:notice] = l(:notice_successful_delete)
        redirect_back_or_default sla_holidays_path
      end
      format.api { render_api_ok }
    end
  end

  # Context menu for bulk actions on SLA Holidays.
  def context_menu
    if @sla_holidays.size == 1
      @sla_holiday = @sla_holidays.first
    end

    can_show   = @sla_holidays.detect { |c| !c.visible?   }.nil?
    can_edit   = @sla_holidays.detect { |c| !c.editable? }.nil?
    can_delete = @sla_holidays.detect { |c| !c.deletable? }.nil?
    @can = { show: can_show, edit: can_edit, delete: can_delete }

    @back = back_url
    @sla_holiday_ids, @safe_attributes, @selected = [], [], {}

    @sla_holidays.each do |e|
      @sla_holiday_ids << e.id
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

  # Find a single SLA Holiday and ensure it is visible.
  def find_sla_holiday
    @sla_holiday = SlaHoliday.find(params[:id])
    raise Unauthorized unless @sla_holiday.visible?
    raise ActiveRecord::RecordNotFound if @sla_holiday.nil?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Find multiple SLA Holidays for bulk actions.
  def find_sla_holidays
    params[:ids]   = params[:id].nil? ? params[:ids] : [params[:id]]
    @sla_holidays  = SlaHoliday.find(params[:ids]).to_a
    @sla_holiday   = @sla_holidays.first if @sla_holidays.count == 1
    raise Unauthorized unless @sla_holidays.all?(&:visible?)
    raise ActiveRecord::RecordNotFound if @sla_holidays.empty?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Load the default query if none is explicitly selected.
  def retrieve_default_query(use_session)
    return if params[:query_id].present?
    return if api_request?
    return if params[:set_filter]

    if params[:without_default].present?
      params[:set_filter] = 1
      return
    end

    if !params[:set_filter] && use_session && session[:sla_holiday_query]
      query_id = session[:sla_holiday_query].values_at(:id)
      return if SlaHolidayQuery.where(id: query_id).exists?
    end

    if default_query = SlaHolidayQuery.default()
      params[:query_id] = default_query.id
    end
  end

  # Returns the SlaHolidayQuery scope for index and report actions.
  def sla_holiday_scope(options = {})
    @query.results_scope(options)
  end

  # Initialize or restore the SlaHolidayQuery.
  def retrieve_sla_holiday_query
    retrieve_query(SlaHolidayQuery, false, :defaults => @default_columns_names)
  end

  # Clean query state on error and delegate to parent handler.
  def query_error(exception)
    session.delete(:sla_holiday_query)
    super
  end    

end