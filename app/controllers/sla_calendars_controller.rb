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

  unloadable

  before_action :require_admin, except: [:show]

  before_action :find_sla_calendar, only: [:show, :edit, :update]
  before_action :find_sla_calendars, only: [:context_menu, :destroy]

  before_action :authorize_global

  helper :sla_calendars
  helper :context_menus
  helper :queries
  include QueriesHelper

  def index
    retrieve_query(Queries::SlaCalendarQuery) 
    @entity_count = @query.sla_calendars.count
    @entity_pages = Paginator.new @entity_count, per_page_option, params['page']
    @entities = @query.sla_calendars(offset: @entity_pages.offset, limit: @entity_pages.per_page) 
  end

  def new
    @sla_calendar = SlaCalendar.new
    @sla_calendar.safe_attributes = params[:sla_calendar]
  end

  def create
    @sla_calendar = SlaCalendar.new()
    @sla_calendar.safe_attributes = params[:sla_calendar]
    if @sla_calendar.save
      flash[:notice] = l(:notice_successful_create)
      redirect_back_or_default sla_calendars_path
    else
      render :new
    end
  end

  def update
    @sla_calendar.safe_attributes = params[:sla_calendar]
    if @sla_calendar.update(sla_calendar_params)
      flash[:notice] = l(:notice_successful_update)
      redirect_back_or_default sla_calendars_path
    else
      render :edit
    end
  end

  def destroy
    @sla_calendars.each(&:destroy)
    flash[:notice] = l(:notice_successful_delete)
    redirect_back_or_default sla_calendars_path
  end

  def context_menu
    Rails.logger.warn "======>>> controllers / sla_calendar->context_menu() <<<====== "
    if @sla_calendars.size == 1
      @sla_calendar = @sla_calendars.first
    end
    can_edit = @sla_calendars.detect{|c| !c.editable?}.nil?
    can_delete = @sla_calendars.detect{|c| !c.deletable?}.nil?
    @can = {edit: can_edit, delete: can_delete}
    @back = back_url
    @sla_calendar_ids, @safe_attributes, @selected = [], [], {}
    @sla_calendars.each do |e|
      @sla_calendar_ids << e.id
      @safe_attributes.concat e.safe_attribute_names
      attributes = e.safe_attribute_names - (%w(custom_field_values custom_fields))
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
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_sla_calendars
    @sla_calendars = SlaCalendar.visible.where(id: (params[:id]||params[:ids])).to_a
    raise ActiveRecord::RecordNotFound if @sla_calendars.empty?
    #raise Unauthorized unless @sla_calendars.all?(&:visible?)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  #def sla_calendar_params
  #  params.require(:sla_calendar).permit(:name, sla_schedules_attributes: [:_destroy, :id, :dow, :start_time, :end_time, :match] )
  #end

  def sla_calendar_params
    Rails.logger.warn "======>>> controllers / sla_calendar->sla_calendar_params() <<<====== "
    params.require(:sla_calendar).permit(:name, sla_schedules_attributes: SlaSchedule.attribute_names.map(&:to_sym).push(:_destroy) )
    #params.require(:sla_calendar).permit(:name, sla_schedules_attributes: [:sla_calendar_id, :dow, :start_time, :end_time, :match])
    #sla_calendar_params = params.permit(:sla_calendar_id, :dow, :start_time, :end_time, :match)
    #sla_calendar_params.merge! ({sla_schedules_attributes: params[:sla_schedules]}) if params[:sla_schedules].present?
    #sla_calendar_params
  end    

end