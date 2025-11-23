# frozen_string_literal: true

# File: redmine_sla/app/controllers/sla_types_controller.rb
# Purpose:
#   Manage SLA Types, the root definition of each SLA category
#   (e.g. Resolution time, Response time). Supports:
#     - listing via SlaTypeQuery
#     - creation/update/deletion
#     - dynamic creation of SLA helper methods (post_create / post_destroy)
#     - bulk actions through context_menu
#     - API access for index/show/create/update/destroy
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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
# ------------------------------------------------------------------------------

class SlaTypesController < ApplicationController

  accept_api_auth :index, :create, :show, :update, :destroy
  
  before_action :require_admin
  before_action :authorize_global

  before_action :find_sla_type,  only: [:show, :edit, :update]
  before_action :find_sla_types, only: [:destroy, :context_menu]

  helper :sla_types
  helper :context_menus

  helper :queries
  include QueriesHelper

  helper Queries::SlaTypesQueriesHelper
  include Queries::SlaTypesQueriesHelper   

  # List all SLA types through query / filter / pagination
  def index
    retrieve_query(SlaTypeQuery)

    @entity_count = @query.sla_types.count
    @entity_pages = Paginator.new @entity_count, per_page_option, params['page']
    @entities     = @query.sla_types(
      offset: @entity_pages.offset,
      limit:  @entity_pages.per_page
    )

    respond_to do |format|
      format.html
      format.api { @offset, @limit = api_offset_and_limit }
    end
  end

  # Render form for a new SLA type
  def new
    @sla_type = SlaType.new
    @sla_type.safe_attributes = params[:sla_type]
  end

  # Create SLA type and dynamically add helper methods
  def create
    @sla_type = SlaType.new
    @sla_type.safe_attributes = params[:sla_type]

    if @sla_type.save
      post_create

      respond_to do |format|
        format.html do
          flash[:notice] = l(
            "sla_label.sla_type.notice_successful_create",
            id: view_context.link_to("##{@sla_type.id}", sla_type_path(@sla_type), title: @sla_type.name)
          )
          redirect_back_or_default sla_types_path
        end

        format.api do
          render :show, status: :created, location: sla_type_url(@sla_type)
        end
      end

    else
      respond_to do |format|
        format.html { render :new }
        format.api  { render_validation_errors(@sla_type) }
      end
    end
  end

  # Update SLA type
  def update
    @sla_type.safe_attributes = params[:sla_type]

    if @sla_type.save
      respond_to do |format|
        format.html do
          flash[:notice] = l(
            "sla_label.sla_type.notice_successful_update",
            id: view_context.link_to("##{@sla_type.id}", sla_type_path(@sla_type), title: @sla_type.name)
          )
          redirect_back_or_default sla_types_path
        end
        format.api { render_api_ok }
      end

    else
      respond_to do |format|
        format.html { render :edit }
        format.api  { render_validation_errors(@sla_type) }
      end
    end
  end

  # Delete one or multiple SLA types
  def destroy
    @sla_types.each do |sla_type|
      begin
        sla_type.reload.destroy
      rescue ActiveRecord::RecordNotFound
      end
    end

    respond_to do |format|
      format.html do
        flash[:notice] = l(:notice_successful_delete)
        redirect_back_or_default sla_types_path
      end
      format.api { render_api_ok }
    end
  end

  # Context menu for bulk actions
  def context_menu
    @sla_type = @sla_types.first if @sla_types.size == 1

    can_show   = @sla_types.none? { |t| !t.visible? }
    can_edit   = @sla_types.none? { |t| !t.editable? }
    can_delete = @sla_types.none? { |t| !t.deletable? }
    @can = { show: can_show, edit: can_edit, delete: can_delete }

    @back = back_url
    @sla_type_ids, @safe_attributes, @selected = [], [], {}

    @sla_types.each do |e|
      @sla_type_ids << e.id
      @safe_attributes.concat e.safe_attribute_names

      e.safe_attribute_names.each do |attr|
        col = attr.to_sym
        @selected[col] = @selected.key?(col) && @selected[col] != e.send(col) ? nil : e.send(col)
      end
    end

    @safe_attributes.uniq!
    render layout: false
  end

  private

  # Find single SLA type
  def find_sla_type
    @sla_type = SlaType.find(params[:id])
    raise Unauthorized unless @sla_type.visible?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Find multiple SLA types
  def find_sla_types
    params[:ids] = params[:id] ? [params[:id]] : params[:ids]
    @sla_types = SlaType.find(params[:ids]).to_a
    @sla_type = @sla_types.first if @sla_types.size == 1

    raise Unauthorized unless @sla_types.all?(&:visible?)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Restore or initialize default query
  def retrieve_default_query(use_session)
    return if params[:query_id].present?
    return if api_request? || params[:set_filter]

    if params[:without_default].present?
      params[:set_filter] = 1
      return
    end

    if use_session && session[:sla_type_query]
      query_id = session[:sla_type_query].values_at(:id)
      return if SlaTypeQuery.where(id: query_id).exists?
    end

    if (default = SlaTypeQuery.default)
      params[:query_id] = default.id
    end
  end

  # Query scope
  def sla_type_scope(options = {})
    @query.results_scope(options)
  end

  # Load query
  def retrieve_sla_type_query
    retrieve_query(SlaTypeQuery, false, defaults: @default_columns_names)
  end

  # Handle query errors
  def query_error(exception)
    session.delete(:sla_type_query)
    super
  end

  # After creating a new SLA type, dynamically define SLA accessor methods
  def post_create
    sla_type = @sla_type

    RedmineSla::Patches::TimeEntryPatch.define_method("get_sla_respect_#{sla_type.id}") do
      issue.get_sla_respect(sla_type.id)
    end

    RedmineSla::Patches::IssuePatch.define_method("get_sla_respect_#{sla_type.id}") do
      get_sla_respect(sla_type.id)
    end

    SlaCache.define_method("get_sla_respect_#{sla_type.id}") { issue.get_sla_respect(sla_type.id) }
    SlaCache.define_method("get_sla_remain_#{sla_type.id}")  { issue.get_sla_remain(sla_type.id) }
    SlaCache.define_method("get_sla_spent_#{sla_type.id}")   { issue.get_sla_spent(sla_type.id) }
    SlaCache.define_method("get_sla_term_#{sla_type.id}")    { issue.get_sla_term(sla_type.id) }
  end

  # After deleting an SLA type, remove dynamically created methods
  def post_destroy
    sla_type = @sla_type

    RedmineSla::Patches::TimeEntryPatch.class_eval { remove_method "get_sla_respect_#{sla_type.id}" }
    RedmineSla::Patches::IssuePatch.class_eval     { remove_method "get_sla_respect_#{sla_type.id}" }

    SlaCache.class_eval { remove_method "get_sla_respect_#{sla_type.id}" }
    SlaCache.class_eval { remove_method "get_sla_remain_#{sla_type.id}" }
    SlaCache.class_eval { remove_method "get_sla_spent_#{sla_type.id}" }
    SlaCache.class_eval { remove_method "get_sla_term_#{sla_type.id}" }
  end

end