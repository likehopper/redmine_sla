# frozen_string_literal: true

# File: redmine_sla/app/controllers/slas_controller.rb
# Purpose:
#   Manage the main SLA definitions:
#     - list all SLAs using SlaQuery
#     - create / update / delete SLAs
#     - expose SLAs through the REST API
#     - provide a context menu for bulk operations
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

class SlasController < ApplicationController

  # It's possible to view and manage SLA via API
  accept_api_auth :index, :create, :show, :update, :destroy
  
  # Only global administrators are allowed to view and manage SLAs.
  before_action :require_admin
  before_action :authorize_global

  before_action :find_sla,  only: [:show, :edit, :update]
  before_action :find_slas, only: [:destroy, :context_menu]

  helper :slas
  helper :context_menus

  helper :queries
  include QueriesHelper

  helper Queries::SlasQueriesHelper
  include Queries::SlasQueriesHelper  

  # ---------------------------------------------------------------------------
  # LIST / FILTER
  # ---------------------------------------------------------------------------
  # List SLAs using SlaQuery (Redmine-style custom queries + filters).
  def index
    retrieve_query(SlaQuery)

    @entity_count = @query.slas.count
    @entity_pages = Paginator.new @entity_count, per_page_option, params['page']
    @entities     = @query.slas(
      offset: @entity_pages.offset,
      limit:  @entity_pages.per_page
    )

    respond_to do |format|
      format.html
      format.api do
        @offset, @limit = api_offset_and_limit
      end
    end
  end

  # ---------------------------------------------------------------------------
  # NEW / CREATE
  # ---------------------------------------------------------------------------
  def new
    @sla = Sla.new
    @sla.safe_attributes = params[:sla]
  end

  # Create a new SLA definition.
  def create
    @sla = Sla.new
    @sla.safe_attributes = params[:sla]

    if @sla.save
      respond_to do |format|
        format.html do
          flash[:notice] = l(
            "sla_label.sla.notice_successful_create",
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
        format.api  { render_validation_errors(@sla) }
      end
    end
  end

  # ---------------------------------------------------------------------------
  # UPDATE
  # ---------------------------------------------------------------------------
  def update
    @sla.safe_attributes = params[:sla]

    if @sla.save
      respond_to do |format|
        format.html do
          flash[:notice] = l(
            "sla_label.sla.notice_successful_update",
            :id => view_context.link_to("##{@sla.id}", sla_path(@sla), :title => @sla.name)
          )
          redirect_back_or_default slas_path
        end
        format.api { render_api_ok }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
        format.api  { render_validation_errors(@sla) }
      end
    end
  end

  # ---------------------------------------------------------------------------
  # DELETE / BULK DELETE
  # ---------------------------------------------------------------------------
  def destroy
    # Reload each SLA to ensure it still exists and then destroy it.
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

  # ---------------------------------------------------------------------------
  # CONTEXT MENU
  # ---------------------------------------------------------------------------
  # Context menu for bulk operations on SLAs.
  def context_menu
    @sla = @slas.first if @slas.size == 1

    can_show   = @slas.detect { |c| !c.visible?   }.nil?
    can_edit   = @slas.detect { |c| !c.editable? }.nil?
    can_delete = @slas.detect { |c| !c.deletable? }.nil?
    @can = { show: can_show, edit: can_edit, delete: can_delete }

    @back = back_url
    @sla_ids, @safe_attributes, @selected = [], [], {}

    @slas.each do |e|
      @sla_ids << e.id
      @safe_attributes.concat e.safe_attribute_names

      attributes = e.safe_attribute_names
      attributes.each do |attr|
        column_name = attr.to_sym
        if @selected.key?(column_name)
          @selected[column_name] = nil if @selected[column_name] != e.send(column_name)
        else
          @selected[column_name] = e.send(column_name)
        end
      end
    end

    @safe_attributes.uniq!
    render layout: false
  end
 
  # ---------------------------------------------------------------------------
  # PRIVATE HELPERS
  # ---------------------------------------------------------------------------
  private

  # Load a single SLA and ensure it is visible to the current user.
  def find_sla
    @sla = Sla.find(params[:id])
    raise Unauthorized unless @sla.visible?
    raise ActiveRecord::RecordNotFound if @sla.nil?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Load multiple SLAs (for bulk actions).
  def find_slas
    params[:ids] = params[:id].nil? ? params[:ids] : [params[:id]]
    @slas = Sla.find(params[:ids])
    @sla  = @slas.first if @slas.count == 1
    raise Unauthorized unless @slas.all?(&:visible?)
    raise ActiveRecord::RecordNotFound if @slas.empty?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Restore or initialize default query for SLAs.
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

    if default_query = SlaQuery.default
      params[:query_id] = default_query.id
    end
  end  

  # Returns the SlaQuery scope for index and report actions.
  def sla_scope(options = {})
    @query.results_scope(options)
  end

  # Load the SlaQuery instance for this request.
  def retrieve_sla_query
    retrieve_query(SlaQuery, false, :defaults => @default_columns_names)
  end

  # Clear saved query in session on invalid query error.
  def query_error(exception)
    session.delete(:sla_query)
    super
  end  

end