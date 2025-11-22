# frozen_string_literal: true

# File: redmine_sla/app/controllers/sla_levels_controller.rb
# Purpose:
#   Manage SLA Levels, which define the SLA configuration (calendar, custom
#   field, etc.) and their associated terms. This controller provides:
#     - listing via SlaLevelQuery,
#     - creation and update of SLA Levels,
#     - translation of nested SLA Level Terms parameters (sla_level_params),
#     - deletion and context menu actions,
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

class SlaLevelsController < ApplicationController

  accept_api_auth :index, :create, :show, :update, :destroy
  
  before_action :require_admin, except: [:show]
  before_action :authorize_global

  before_action :find_sla_level,  only: [:show, :edit, :update, :sla_terms]
  before_action :find_sla_levels, only: [:destroy, :context_menu]

  before_action :authorize_global

  helper :sla_levels
  helper :context_menus

  helper :queries
  include QueriesHelper

  helper Queries::SlaLevelsQueriesHelper
  include Queries::SlaLevelsQueriesHelper 

  # List SLA Levels with filters and pagination.
  def index
    retrieve_query(SlaLevelQuery)
    @entity_count = @query.sla_levels.count
    @entity_pages = Paginator.new @entity_count, per_page_option, params['page']
    @entities     = @query.sla_levels(
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

  # Render form for a new SLA Level.
  def new
    @sla_level = SlaLevel.new
    @sla_level.safe_attributes = params[:sla_level]
  end

  # Create a new SLA Level.
  def create
    @sla_level = SlaLevel.new
    @sla_level.safe_attributes = params[:sla_level]

    if @sla_level.save
      respond_to do |format|
        format.html do
          flash[:notice] = l(
            "sla_label.sla_level.notice_successful_create",
            :id => view_context.link_to("##{@sla_level.id}", sla_level_path(@sla_level), :title => @sla_level.name)
          )
          redirect_back_or_default sla_levels_path
        end
        format.api do
          render :action => 'show', :status => :created,
                 :location => sla_level_url(@sla_level)
        end
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.api  { render_validation_errors(@sla_level) }
      end
    end
  end

  # Update an existing SLA Level.
  # May also update its associated SLA Level Terms via sla_level_params.
  def update
    @sla_level.safe_attributes = params[:sla_level]

    # When nested SLA Level Terms are present, normalize params structure first.
    if !params[:sla_level][:sla_level_terms_attributes].nil?
      @sla_level.update(sla_level_params)
    end

    # If the custom field changes, SLA cache must eventually be purged.
    if @sla_level.custom_field_id_changed?
      flash[:warning] = l('sla_label.sla_level.purge')
    end    

    if @sla_level.save
      respond_to do |format|
        format.html do 
          flash[:notice] = l(
            "sla_label.sla_level.notice_successful_update",
            :id => view_context.link_to("##{@sla_level.id}", sla_level_path(@sla_level), :title => @sla_level.name)
          )
          redirect_back_or_default sla_levels_path
        end
        format.api { render_api_ok }
      end
    else
      respond_to do |format|
        format.html do
          if params[:sla_level][:sla_level_terms_attributes].nil?
            render :action => 'edit'
          else
            render :action => 'sla_terms'
          end
        end 
        format.api { render_validation_errors(@sla_level) }
      end
    end
  end

  # Render the dedicated view for SLA Level Terms.
  def sla_terms
    respond_to do |format|
      format.html
    end
  end  

  # Destroy one or multiple SLA Levels.
  def destroy
    @sla_levels.each do |sla_level|
      begin
        sla_level.reload.destroy
      rescue ::ActiveRecord::RecordNotFound
      end
    end
    respond_to do |format|
      format.html do
        flash[:notice] = l(:notice_successful_delete)
        redirect_back_or_default sla_levels_path
      end
      format.api { render_api_ok }
    end
  end

  # Context menu for bulk actions on SLA Levels.
  def context_menu
    if @sla_levels.size == 1
      @sla_level = @sla_levels.first
    end

    can_show   = @sla_levels.detect { |c| !c.visible?   }.nil?
    can_edit   = @sla_levels.detect { |c| !c.editable? }.nil?
    can_delete = @sla_levels.detect { |c| !c.deletable? }.nil?
    @can = { show: can_show, edit: can_edit, delete: can_delete }

    @back = back_url
    @sla_level_ids, @safe_attributes, @selected = [], [], {}

    @sla_levels.each do |e|
      @sla_level_ids << e.id
      @safe_attributes.concat e.safe_attribute_names

      attributes = e.safe_attribute_names
      attributes.each do |c|
        column_name = c.to_sym
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
 
  private

  # Find a single SLA Level and ensure it is visible.
  def find_sla_level
    @sla_level = SlaLevel.find(params[:id])
    raise Unauthorized unless @sla_level.visible?
    raise ActiveRecord::RecordNotFound if @sla_level.nil?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Find multiple SLA Levels for bulk actions.
  def find_sla_levels
    params[:ids] = params[:id].nil? ? params[:ids] : [params[:id]]
    @sla_levels  = SlaLevel.find(params[:ids]).to_a
    @sla_level   = @sla_levels.first if @sla_levels.count == 1
    raise Unauthorized unless @sla_levels.all?(&:visible?)
    raise ActiveRecord::RecordNotFound if @sla_levels.empty?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def sla_level_params
    sla_level_terms = []

    params[:sla_level][:sla_level_terms_attributes].each do |sla_type_id, sla_priorities|
      sla_priorities.each do |sla_priority_id, sla_terms|
        sla_level_terms << {
          id:            sla_terms[:id],
          sla_level_id:  @sla_level.id,
          sla_type_id:   sla_type_id,
          sla_priority_id: sla_priority_id,
          term:          (sla_terms[:term].empty? ? nil : sla_terms[:term]),
          _destroy:      sla_terms[:term].empty?
        }.compact
      end
    end

    params[:sla_level][:sla_level_terms_attributes] = sla_level_terms
    params.require(:sla_level).permit(
      sla_level_terms_attributes: SlaLevelTerm.attribute_names.map(&:to_sym).push(:_destroy)
    )
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

    if !params[:set_filter] && use_session && session[:sla_level_query]
      query_id = session[:sla_level_query].values_at(:id)
      return if SlaLevelQuery.where(id: query_id).exists?
    end

    if default_query = SlaLevelQuery.default
      params[:query_id] = default_query.id
    end
  end  

  # Returns the SlaLevelQuery scope for index and report actions.
  def sla_level_scope(options = {})
    @query.results_scope(options)
  end

  # Initialize or restore SlaLevelQuery.
  def retrieve_sla_level_query
    retrieve_query(SlaLevelQuery, false, :defaults => @default_columns_names)
  end

  # Handle query errors and clean stored SLA Level query state.
  def query_error(exception)
    session.delete(:sla_level_query)
    super
  end  
  
end
