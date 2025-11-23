# frozen_string_literal: true

# File: redmine_sla/app/controllers/sla_cache_spents_controller.rb
# Redmine SLA - Redmine Plugin
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

class SlaCacheSpentsController < ApplicationController
  default_search_scope :sla_cache_spents

  

  accept_api_auth :index, :show, :refresh, :destroy, :purge

  # Only administrators can manage SLA cache spents through the UI/API,
  # except for a few read actions.
  before_action :require_admin, except: [:index, :show, :refresh, :destroy, :context_menu]
  before_action :authorize_global

  before_action :find_sla_cache_spent, only: [:show]
  before_action :find_sla_cache_spents, only: [:refresh, :destroy, :context_menu]

  # Project is optional: when present, restricts scope to a single project.
  before_action :find_optional_project, only: [:index, :show, :refresh, :destroy, :purge]

  rescue_from Query::StatementInvalid, with: :query_statement_invalid
  rescue_from Query::QueryError, with: :query_error

  helper :sla_cache_spents
  helper :context_menus

  helper :queries
  include QueriesHelper

  helper Queries::SlaCacheSpentsQueriesHelper
  include Queries::SlaCacheSpentsQueriesHelper

  # List SLA cache spents with Redmine's generic query system
  def index
    use_session = !request.format.csv?
    retrieve_default_query(use_session)
    retrieve_query(SlaCacheSpentQuery, use_session)

    # Base scope used by all formats
    scope = sla_cache_spent_scope.
      preload(sla_cache: { issue: [:project, :tracker, :status, :priority] }).
      preload(:sla_type).
      preload(:project)

    respond_to do |format|
      format.html do
        @entity_count = scope.count
        @entity_pages = Paginator.new @entity_count, per_page_option, params['page']
        @entities = scope.offset(@entity_pages.offset).limit(@entity_pages.per_page).to_a
        render layout: !request.xhr?
      end
      format.api do
        @entity_count = scope.count
        @offset, @limit = api_offset_and_limit
        @entities = scope.offset(@offset).limit(@limit).to_a
      end
      format.atom do
        entities = scope.limit(Setting.feeds_limit.to_i)
                        .reorder("#{SlaCacheSpent.table_name}.updated_on DESC")
                        .to_a
        render_feed(entities, title: l(:label_sla_cache_spent))
      end
      format.csv do
        # Export all entities that match the current query
        @entities = scope.to_a
        send_data(
          query_to_csv(@entities, @query, params),
          type: 'text/csv; header=present',
          filename: "#{filename_for_export(@query, 'sla_cache_spents')}.csv"
        )
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Show is not really used: we just redirect to the list
  def show
    respond_to do |format|
      format.html { redirect_back_or_default sla_cache_spents_path }
      format.api {}
    end
  end

  # Recompute the spent cache for the selected records
  def refresh
    @sla_cache_spents.each do |sla_cache_spent|
      begin
        sla_cache_spent.reload.refresh
      rescue ::ActiveRecord::RecordNotFound
        # Swallow the error: the record has been removed meanwhile
      end
    end

    respond_to do |format|
      format.html do
        flash[:notice] = l(:notice_successful_refresh)
        redirect_to_referer_or(@project.nil? ? sla_cache_spents_path : project_sla_cache_spents_path(@project))
      end
      format.api { render_api_ok }
    end
  end

  # Purge all cache spents for a given project (or globally if no project)
  def purge
    SlaCacheSpent.purge(@project)
    respond_to do |format|
      format.html do
        flash[:notice] = l(:notice_successful_purge)
        redirect_to_referer_or(@project.nil? ? sla_cache_spents_path : project_sla_cache_spents_path(@project))
      end
      format.api { render_api_ok }
    end
  end

  # Delete selected cache spents
  def destroy
    @sla_cache_spents.each do |sla_cache_spent|
      begin
        sla_cache_spent.reload.destroy
      rescue ::ActiveRecord::RecordNotFound
        # Ignore already removed records
      end
    end
    respond_to do |format|
      format.html do
        flash[:notice] = l(:notice_successful_delete)
        redirect_to_referer_or(@project.nil? ? sla_cache_spents_path : project_sla_cache_spents_path(@project))
      end
      format.api { render_api_ok }
    end
  end

  # Context menu for bulk actions
  def context_menu
    @sla_cache_spent = @sla_cache_spents.first if @sla_cache_spents.size == 1

    can_show    = @sla_cache_spents.detect { |c| !c.visible? }.nil?
    can_refresh = @sla_cache_spents.detect { |c| !c.visible? }.nil?
    can_delete  = @sla_cache_spents.detect { |c| !c.deletable? }.nil?

    @can = { show: can_show, refresh: can_refresh, delete: can_delete }
    @back = back_url

    @sla_cache_spent_ids, @safe_attributes, @selected = [], [], {}

    @sla_cache_spents.each do |e|
      @sla_cache_spent_ids << e.id
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

  # Find a single SlaCacheSpent by id
  def find_sla_cache_spent
    @sla_cache_spent = SlaCacheSpent.find(params[:id])
    raise Unauthorized unless @sla_cache_spent.visible?
    raise ActiveRecord::RecordNotFound if @sla_cache_spent.nil?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Find a collection of SlaCacheSpent for mass-actions
  def find_sla_cache_spents
    params[:ids] = params[:id].nil? ? params[:ids] : [params[:id]]
    @sla_cache_spents = SlaCacheSpent.find(params[:ids]).to_a
    @sla_cache_spent = @sla_cache_spents.first if @sla_cache_spents.count == 1
    raise Unauthorized unless @sla_cache_spents.all?(&:visible?)
    raise ActiveRecord::RecordNotFound if @sla_cache_spents.empty?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Initialize the default query for the current context (project / global)
  def retrieve_default_query(use_session)
    return if params[:query_id].present?
    return if api_request?
    return if params[:set_filter]

    if params[:without_default].present?
      params[:set_filter] = 1
      return
    end

    if !params[:set_filter] && use_session && session[:sla_cache_spent_query]
      query_id, project_id = session[:sla_cache_spent_query].values_at(:id, :project_id)
      return if SlaCacheSpentQuery.where(id: query_id).exists? && project_id == @project&.id
    end

    if (default_query = SlaCacheSpentQuery.default(project: @project))
      params[:query_id] = default_query.id
    end
  end

  # Returns the SlaCacheSpentQuery scope for index and report actions
  def sla_cache_spent_scope(options = {})
    @query.results_scope(options)
  end

  def retrieve_sla_cache_spent_query
    retrieve_query(SlaCacheSpentQuery, false, defaults: @default_columns_names)
  end

  def query_error(exception)
    session.delete(:sla_cache_spent_query)
    super
  end
end