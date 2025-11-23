# frozen_string_literal: true

# File: redmine_sla/app/controllers/sla_level_terms_controller.rb
# Purpose:
#   Manage SLA Level Terms, which define the SLA target time (term) per
#   (SLA Level × Priority × SLA Type). This includes:
#     - listing via SlaLevelTermQuery,
#     - creation and update,
#     - bulk delete and context menu actions,
#     - API access to index/show/create/update/destroy.
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

class SlaLevelTermsController < ApplicationController

  accept_api_auth :index, :create, :show, :update, :destroy
  
  before_action :require_admin
  before_action :authorize_global

  before_action :find_sla_level_term,  only: [:show, :edit, :update]
  before_action :find_sla_level_terms, only: [:destroy, :context_menu]

  helper :sla_level_terms
  helper :context_menus

  helper :queries
  include QueriesHelper

  helper Queries::SlaLevelTermsQueriesHelper
  include Queries::SlaLevelTermsQueriesHelper 

  # List SLA Level Terms with query/pagination support.
  def index
    use_session = !request.format.csv?
    retrieve_default_query(use_session)
    retrieve_query(SlaLevelTermQuery, use_session)

    @entity_count = @query.sla_level_terms.count
    @entity_pages = Paginator.new @entity_count, per_page_option, params['page']
    @entities     = @query.sla_level_terms(
      offset: @entity_pages.offset,
      limit:  @entity_pages.per_page
    )

    respond_to do |format|
      format.html
      format.api { @offset, @limit = api_offset_and_limit }
    end
  end

  # Direct creation/editing by UI is forbidden.
  def new
    raise Unauthorized
  end

  def edit
    raise Unauthorized
  end

  # Create via API (internal logic normally uses rake tasks / automated builders).
  def create
    @sla_level_term = SlaLevelTerm.new
    @sla_level_term.safe_attributes = params[:sla_level_term]

    if @sla_level_term.save
      respond_to do |format|
        format.html do
          flash[:notice] = l(
            "sla_label.sla_level_term.notice_successful_create",
            :id => view_context.link_to("##{@sla_level_term.id}", sla_level_term_path(@sla_level_term), :title => @sla_level_term.name)
          )
          redirect_back_or_default sla_level_terms_path
        end
        format.api do
          render :action => 'show', :status => :created,
                 :location => sla_level_term_url(@sla_level_term)
        end
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.api  { render_validation_errors(@sla_level_term) }
      end
    end
  end

  # Update an SLA Level Term.
  def update
    @sla_level_term.safe_attributes = params[:sla_level_term]

    if @sla_level_term.save
      respond_to do |format|
        format.html do
          flash[:notice] = l(
            "sla_label.sla_level_term.notice_successful_update",
            :id => view_context.link_to("##{@sla_level_term.id}", sla_level_term_path(@sla_level_term), :title => @sla_level_term.name)
          )
          redirect_back_or_default sla_level_terms_path
        end
        format.api { render_api_ok }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
        format.api  { render_validation_errors(@sla_level_term) }
      end
    end
  end

  # Bulk destroy.
  def destroy
    @sla_level_terms.each do |sla_level_term|
      begin
        sla_level_term.reload.destroy
      rescue ::ActiveRecord::RecordNotFound
      end
    end

    respond_to do |format|
      format.html do
        flash[:notice] = l(:notice_successful_delete)
        redirect_back_or_default sla_level_terms_path
      end
      format.api { render_api_ok }
    end
  end

  # Context menu for bulk actions.
  def context_menu
    if @sla_level_terms.size == 1
      @sla_level_term = @sla_level_terms.first
    end

    can_show   = @sla_level_terms.all?(&:visible?)
    can_edit   = @sla_level_terms.all?(&:editable?)
    can_delete = @sla_level_terms.all?(&:deletable?)

    @can = { show: can_show, edit: can_edit, delete: can_delete }
    @back = back_url

    @sla_level_term_ids, @safe_attributes, @selected = [], [], {}

    @sla_level_terms.each do |e|
      @sla_level_term_ids << e.id
      @safe_attributes.concat e.safe_attribute_names

      e.safe_attribute_names.each do |attr|
        column = attr.to_sym
        if @selected.key?(column)
          @selected[column] = nil if @selected[column] != e.send(column)
        else
          @selected[column] = e.send(column)
        end
      end
    end

    @safe_attributes.uniq!
    render layout: false
  end
 
  private

  # Find a single SLA Level Term.
  def find_sla_level_term
    @sla_level_term = SlaLevelTerm.find(params[:id])
    raise Unauthorized unless @sla_level_term.visible?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Find multiple level terms for bulk actions.
  def find_sla_level_terms
    params[:ids] ||= [params[:id]] if params[:id]
    @sla_level_terms = SlaLevelTerm.find(params[:ids]).to_a
    @sla_level_term  = @sla_level_terms.first if @sla_level_terms.size == 1

    raise Unauthorized unless @sla_level_terms.all?(&:visible?)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Load default query if none is selected.
  def retrieve_default_query(use_session)
    return if params[:query_id].present?
    return if api_request?
    return if params[:set_filter]

    if params[:without_default].present?
      params[:set_filter] = 1
      return
    end

    if use_session && session[:sla_level_term_query]
      query_id = session[:sla_level_term_query].values_at(:id)
      return if SlaLevelTermQuery.where(id: query_id).exists?
    end

    if default_query = SlaLevelTermQuery.default
      params[:query_id] = default_query.id
    end
  end  

  # Scope from the query object.
  def sla_level_term_scope(options = {})
    @query.results_scope(options)
  end

  # Restore/initialize SlaLevelTermQuery.
  def retrieve_sla_level_term_query
    retrieve_query(SlaLevelTermQuery, false, :defaults => @default_columns_names)
  end

  # Cleanup on query failure.
  def query_error(exception)
    session.delete(:sla_level_term_query)
    super
  end

end