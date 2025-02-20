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

class SlasController < ApplicationController

  unloadable if defined?(Rails) && !Rails.autoloaders.zeitwerk_enabled?

  # It's possible to view and manage SLA via API
  accept_api_auth :index, :create, :show, :update, :destroy
  
  # It's mandatory to be an administrator to view and manage SLA
  before_action :require_admin
  before_action :authorize_global

  before_action :find_sla, only: [ :show, :edit, :update ]
  before_action :find_slas, only: [ :destroy, :context_menu ]

  helper :slas
  helper :context_menus

  helper :queries
  include QueriesHelper

  helper Queries::SlasQueriesHelper
  include Queries::SlasQueriesHelper  

  def index
    retrieve_query(SlaQuery)
    @entity_count = @query.slas.count
    @entity_pages = Paginator.new @entity_count, per_page_option, params['page']
    @entities = @query.slas(offset: @entity_pages.offset, limit: @entity_pages.per_page) 
    respond_to do |format|
      format.html do
      end
      format.api do
        @offset, @limit = api_offset_and_limit
      end
    end
  end

  def new
    @sla = Sla.new
    @sla.safe_attributes = params[:sla]
  end

  def create
    @sla = Sla.new
    @sla.safe_attributes = params[:sla]
    if @sla.save
      respond_to do |format|
        format.html do
          flash[:notice] = l("sla_label.sla.notice_successful_create",
            :id => view_context.link_to("##{@sla.id}", sla_path(@sla), :title => @sla.name)
          )
          redirect_back_or_default slas_path
        end
        format.api do
          render :action => 'show', :status => :created,
            :location => sla_url(@sla)
        end
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.api { render_validation_errors(@sla) }
      end
    end

  end

  def update
    @sla.safe_attributes = params[:sla]
    if @sla.save
      respond_to do |format|
        format.html do
          flash[:notice] = l("sla_label.sla.notice_successful_update",
            :id => view_context.link_to("##{@sla.id}", sla_path(@sla), :title => @sla.name)
          )
          redirect_back_or_default slas_path
        end
        format.api { render_api_ok }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
        format.api { render_validation_errors(@sla) }
      end
    end
  end

  def destroy
    #@slas.each(&:destroy)
    @slas.each do |sla|
      begin
        sla.reload.destroy
      rescue ::ActiveRecord::RecordNotFound
      end
    end
    respond_to do |format|
      format.html do
        flash[:notice] = l(:notice_successful_delete)
        redirect_back_or_default slas_path
      end
      format.api { render_api_ok }
    end
  end

  def context_menu
    if @slas.size == 1
      @sla = @slas.first
    end
    can_show = @slas.detect{|c| !c.visible?}.nil?
    can_edit = @slas.detect{|c| !c.editable?}.nil?
    can_delete = @slas.detect{|c| !c.deletable?}.nil?
    @can = {show: can_show, edit: can_edit, delete: can_delete}
    @back = back_url
    @sla_ids, @safe_attributes, @selected = [], [], {}
    @slas.each do |e|
      @sla_ids << e.id
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

  def find_sla
    @sla = Sla.find(params[:id])
    raise Unauthorized unless @sla.visible?
    raise ActiveRecord::RecordNotFound if @sla.nil?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_slas
    params[:ids] = params[:id].nil? ? params[:ids] : [params[:id]] 
    @slas = Sla.find(params[:ids])
    @sla = @slas.first if @slas.count == 1
    raise Unauthorized unless @slas.all?(&:visible?)
    raise ActiveRecord::RecordNotFound if @slas.empty?
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
    if !params[:set_filter] && use_session && session[:sla_query]
      query_id = session[:sla_query].values_at(:id)
      return if SlaQuery.where(id: query_id).exists?
    end
    if default_query = SlaQuery.default()
      params[:query_id] = default_query.id
    end
  end  

  # Returns the SlaQuery scope for index and report actions
  def sla_scope(options={})
    @query.results_scope(options)
  end

  def retrieve_sla_query
    retrieve_query(SlaQuery, false, :defaults => @default_columns_names)
  end

  def query_error(exception)
    session.delete(:sla_query)
    super
  end  

end