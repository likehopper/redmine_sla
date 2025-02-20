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

class SlaStatusesController < ApplicationController

  unloadable if defined?(Rails) && !Rails.autoloaders.zeitwerk_enabled?

  accept_api_auth :index, :create, :show, :update, :destroy
  
  before_action :require_admin
  before_action :authorize_global

  before_action :find_sla_status, only: [ :show, :edit, :update ]
  before_action :find_sla_statuses, only: [ :destroy, :context_menu ]

  helper :sla_statuses
  helper :context_menus

  helper :queries
  include QueriesHelper

  helper Queries::SlaStatusesQueriesHelper
  include Queries::SlaStatusesQueriesHelper  

  def index
    retrieve_query(SlaStatusQuery) 
    @entity_count = @query.sla_statuses.count
    @entity_pages = Paginator.new @entity_count, per_page_option, params['page']
    @entities = @query.sla_statuses(offset: @entity_pages.offset, limit: @entity_pages.per_page) 
    respond_to do |format|
      format.html do
      end
      format.api do
        @offset, @limit = api_offset_and_limit
      end
    end    
  end

  def new
    @sla_status = SlaStatus.new
    @sla_status.safe_attributes = params[:sla_status]
  end

  def create
    @sla_status = SlaStatus.new
    @sla_status.safe_attributes = params[:sla_status]
    if @sla_status.save
      respond_to do |format|
        format.html do
          flash[:notice] = l("sla_label.sla_status.notice_successful_create",
            :id => view_context.link_to("##{@sla_status.id}", sla_path(@sla_status), :title => @sla_status.sla_type.name+" / "+@sla_status.status.name)
          )
          redirect_back_or_default sla_statuses_path
        end
        format.api do
          render :action => 'show', :status => :created,
            :location => sla_status_url(@sla_status)
        end
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.api { render_validation_errors(@sla_status) }
      end
    end

  end

  def update
    @sla_status.safe_attributes = params[:sla_status]
    if @sla_status.save
      respond_to do |format|
        format.html do
          flash[:notice] = l("sla_label.sla_status.notice_successful_update",
            :id => view_context.link_to("##{@sla_status.id}", sla_path(@sla_status), :title => @sla_status.sla_type.name+" / "+@sla_status.status.name)
          )          
          redirect_back_or_default sla_statuses_path
        end
        format.api { render_api_ok }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
        format.api { render_validation_errors(@sla_status) }
      end
    end
  end

  def destroy
    @sla_statuses.each do |sla_status|
      begin
        sla_status.reload.destroy
      rescue ::ActiveRecord::RecordNotFound
      end
    end
    respond_to do |format|
      format.html do
        flash[:notice] = l(:notice_successful_delete)
        redirect_back_or_default sla_statuses_path
      end
      format.api { render_api_ok }
    end        
  end

  def context_menu
    if @sla_statuses.size == 1
      @sla_status = @sla_statuses.first
    end
    can_show = @sla_statuses.detect{|c| !c.visible?}.nil?
    can_edit = @sla_statuses.detect{|c| !c.editable?}.nil?
    can_delete = @sla_statuses.detect{|c| !c.deletable?}.nil?
    @can = {show: can_show, edit: can_edit, delete: can_delete}
    @back = back_url
    @sla_status_ids, @safe_attributes, @selected = [], [], {}
    @sla_statuses.each do |e|
      @sla_status_ids << e.id
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

  def find_sla_status
    @sla_status = SlaStatus.find(params[:id])
    raise Unauthorized unless @sla_status.visible?
    raise ActiveRecord::RecordNotFound if @sla_status.nil?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_sla_statuses
    params[:ids] = params[:id].nil? ? params[:ids] : [params[:id]] 
    @sla_statuses = SlaStatus.find(params[:ids]).to_a  
    raise Unauthorized unless @sla_statuses.all?(&:visible?)
    raise ActiveRecord::RecordNotFound if @sla_statuses.empty?
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
    if !params[:set_filter] && use_session && session[:sla_status_query]
      query_id = session[:sla_status_query].values_at(:id)
      return if SlaStatusQuery.where(id: query_id).exists?
    end
    if default_query = SlaStatusQuery.default()
      params[:query_id] = default_query.id
    end
  end  

  # Returns the SlaStatusQuery scope for index and report actions
  def sla_status_scope(options={})
    @query.results_scope(options)
  end

  def retrieve_sla_status_query
    retrieve_query(SlaStatusQuery, false, :defaults => @default_columns_names)
  end

  def query_error(exception)
    session.delete(:sla_status_query)
    super
  end

end