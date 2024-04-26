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

class SlaHolidaysController < ApplicationController

  unloadable

  accept_api_auth :index, :create, :show, :update, :destroy
  before_action :require_admin
  before_action :authorize_global

  before_action :find_sla_holiday, only: [:show, :edit, :update]
  before_action :find_sla_holidays, only: [:context_menu, :destroy]

  helper :sla_holidays
  helper :context_menus
  helper :queries
  include QueriesHelper

  def index
    retrieve_query(Queries::SlaHolidayQuery) 
    @entity_count = @query.sla_holidays.count
    @entity_pages = Paginator.new @entity_count, per_page_option, params['page']
    @entities = @query.sla_holidays(offset: @entity_pages.offset, limit: @entity_pages.per_page) 
    respond_to do |format|
      format.html do
      end
      format.api do
        @offset, @limit = api_offset_and_limit
      end
    end    
  end

  def show
    respond_to do |format|
      format.html do
        end
      format.api
    end
  end

  def new
    @sla_holiday = SlaHoliday.new
    @sla_holiday.safe_attributes = params[:sla_holiday]
  end

  def create
    @sla_holiday = SlaHoliday.new
    @sla_holiday.safe_attributes = params[:sla_holiday]
    if @sla_holiday.save
      respond_to do |format|
        format.html do
          flash[:notice] = l(:notice_successful_create)
          redirect_back_or_default sla_holidays_path
        end
        format.api do
          render :action => 'show', :status => :created,
          :location => sla_holiday_url(@sla_holiday)
        end
      end
    else
      respond_to do |format|
        format.html do
          render :action => 'new'
        end
        format.api {render_validation_errors(@sla_holiday)}
      end
    end
  end

  def update
    @sla_holiday.safe_attributes = params[:sla_holiday]
    if @sla_holiday.save
      flash[:notice] = l(:notice_successful_update)
      respond_to do |format|
        format.html do
          redirect_back_or_default sla_holidays_path
        end
        format.api {render_api_ok}
      end
    else
      respond_to do |format|
        format.html {render :action => 'edit'}
        format.api  {render_validation_errors(@sla_holiday)}
      end
    end
  end

  def destroy
    #@sla_holidays.each(&:destroy)
    @sla_holidays.each do |sla_holiday|
      begin
        sla_holiday.reload.destroy
      rescue ::ActiveRecord::RecordNotFound # raised by #reload if sla_holiday no longer exists
        # nothing to do, sla_holiday was already deleted (eg. by a parent)
      end
    end
    respond_to do |format|
      format.html do
        flash[:notice] = l(:notice_successful_delete)
        redirect_back_or_default sla_holidays_path
      end
      format.api {render_api_ok}
    end
  end

  def context_menu
    if @sla_holidays.size == 1
      @sla_holiday = @sla_holidays.first
    end
    can_show = @sla_holidays.detect{|c| !c.visible?}.nil?
    can_edit = @sla_holidays.detect{|c| !c.editable?}.nil?
    can_delete = @sla_holidays.detect{|c| !c.deletable?}.nil?
    @can = {show: can_show, edit: can_edit, delete: can_delete}
    @back = back_url
    @sla_holiday_ids, @safe_attributes, @selected = [], [], {}
    @sla_holidays.each do |e|
      @sla_holiday_ids << e.id
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

  def find_sla_holiday
    @sla_holiday = SlaHoliday.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_sla_holidays
    @sla_holidays = SlaHoliday.visible.where(id: (params[:id]||params[:ids])).to_a
    raise ActiveRecord::RecordNotFound if @sla_holidays.empty?
    #raise Unauthorized unless @sla_holidays.all?(&:visible?)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end