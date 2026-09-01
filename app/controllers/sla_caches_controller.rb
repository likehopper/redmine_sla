# frozen_string_literal: true

# File: redmine_sla/app/controllers/sla_caches_controller.rb
# Purpose:
#   Controller used to list, refresh, purge, delete and manage SLA cache
#   entries (SlaCache). These records store precomputed SLA level data
#   for issues, allowing faster SLA evaluation and reporting.
#
#   This controller:
#     - exposes HTML, API, Atom and CSV exports,
#     - integrates with SlaCacheQuery for filtering/sorting,
#     - supports both global and project-specific contexts,
#     - provides context menu actions for bulk operations.

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

class SlaCachesController < ApplicationController
  default_search_scope :sla_caches
  
  accept_api_auth :index, :show, :refresh, :destroy, :purge

  before_action :require_admin, except: [ :index, :show, :refresh, :destroy, :purge, :context_menu, :explain ]
  before_action :authorize_global

  before_action :find_optional_project, only: [ :index, :show, :refresh, :destroy, :purge, :context_menu ]
  before_action :find_sla_cache,        only: [ :show ]
  before_action :find_sla_caches,       only: [ :refresh, :destroy, :context_menu ]
  before_action :find_issue_for_explain, only: [ :explain ]
  before_action :authorize_cache_management, only: [ :refresh, :destroy, :purge ]
  # before_action :check_routing_users, :only => [ :index, :show, :refresh, :destroy, :purge ]
  
  rescue_from Query::StatementInvalid, :with => :query_statement_invalid
  rescue_from Query::QueryError,       :with => :query_error
  
  helper :sla_caches
  helper :context_menus
  
  helper :queries
  include QueriesHelper

  helper Queries::SlaCachesQueriesHelper
  include Queries::SlaCachesQueriesHelper

  # List SLA cache entries with filters and pagination.
  # Supports HTML, API, Atom and CSV export.
  def index
    use_session = !request.format.csv?
    retrieve_default_query(use_session) 
    retrieve_query(SlaCacheQuery, use_session)

    scope = sla_cache_scope.
      preload(:issue => [:project, :tracker, :status, :priority]).
      preload(:project)

    respond_to do |format|
      format.html do
        @entity_count = scope.count
        @entity_pages = Paginator.new @entity_count, per_page_option, params['page']
        @entities     = scope.offset(@entity_pages.offset).limit(@entity_pages.per_page).to_a
        render :layout => !request.xhr?
      end
      format.api do
        @entity_count = scope.count
        @offset, @limit = api_offset_and_limit
        @entities = scope.offset(@offset).limit(@limit).to_a
      end
      format.atom do
        entities = scope.
          limit(Setting.feeds_limit.to_i).
          reorder("#{SlaCache.table_name}.updated_on DESC").to_a
        render_feed(entities, :title => l(:label_sla_cache))
      end
      format.csv do
        # Export all entities (no pagination)
        @entities = scope.to_a
        send_data(
          query_to_csv(@entities, @query, params),
          :type => 'text/csv; header=present',
          :filename => "#{filename_for_export(@query, 'sla_caches')}.csv"
        )
      end
    end      
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Show a single SLA cache entry.
  def show
    respond_to do |format|
      format.html { redirect_back_or_default sla_caches_path }
      format.api  { }
    end
  end  

  # Refresh SLA cache entries for the selected records.
  # If @project is present, refresh only its caches; otherwise act globally.
  def refresh
    @sla_caches.each do |sla_cache|
      begin
        sla_cache.reload.refresh
      rescue ::ActiveRecord::RecordNotFound
        error = l(:label_sla_msgerror)
      end
    end  
    respond_to do |format|
      format.html do
        flash[:notice] = l(:notice_successful_refresh)
        redirect_to_referer_or ( @project.nil? ? sla_caches_path : project_sla_caches_path(@project) )
      end
      format.api { render_api_ok }
    end    
  end

  # Purge all SLA cache entries for the current project (or globally if no project).
  def purge
    SlaCache.purge(@project)
    respond_to do |format|
      format.html do
        flash[:notice] = l(:notice_successful_purge)
        redirect_to_referer_or ( @project.nil? ? sla_caches_path : project_sla_caches_path(@project) )
      end
      format.api { render_api_ok }
    end    
  end

  # Destroy selected SLA cache entries.
  def destroy # Cache
    @sla_caches.each do |sla_cache|
      begin
        sla_cache.reload.destroy
      rescue ::ActiveRecord::RecordNotFound
      end
    end
    respond_to do |format|
      format.html do
        flash[:notice] = l(:notice_successful_delete)
        redirect_to_referer_or ( @project.nil? ? sla_caches_path : project_sla_caches_path(@project) )
      end
      format.api { render_api_ok }
    end
  end

  # Explain the SLA calculation for a single issue, on demand.
  # Read-only: queries sla_explain_level/sla_explain_spent, which mirror the
  # production functions but never write to sla_caches/sla_cache_spents.
  # Works even when the issue has no SlaCache row yet (e.g. to explain why
  # no SLA level matched at all).
  def explain
    # Normalized through the same sla_get_date() timezone conversion as
    # start_date/from_status_date/etc below, so the two are comparable —
    # @issue.created_on alone is displayed in Redmine's own timezone
    # convention, not the SLA plugin's configured sla_time_zone, and the two
    # can differ by hours with no actual SLA delay involved.
    @issue_created_on_sla_tz = ActiveRecord::Base.connection.select_value(
      ActiveRecord::Base.sanitize_sql(["SELECT sla_get_date(?)", @issue.created_on])
    )

    @sla_level_explanation = ActiveRecord::Base.connection.select_all(
      ActiveRecord::Base.sanitize_sql(["SELECT * FROM sla_explain_level(?)", @issue.id])
    )

    # Business hours of the selected level's calendar, shown once at the top
    # rather than repeated on every day row below.
    selected_level = @sla_level_explanation.to_a.find { |row| row['selected'] }
    @sla_schedule_summary = selected_level ?
      SlaSchedule.where(sla_calendar_id: selected_level['sla_calendar_id'], match: true).order(:dow, :start_time) :
      SlaSchedule.none

    @sla_spent_explanations = SlaType.sorted.filter_map { |sla_type|
      rows = ActiveRecord::Base.connection.select_all(
        ActiveRecord::Base.sanitize_sql(["SELECT * FROM sla_explain_spent(?, ?)", @issue.id, sla_type.id])
      ).to_a
      next if rows.empty?

      # Group day-level rows back under their status interval, so the view
      # can show a subtotal per interval and the day-by-day detail
      # underneath (a long-running status doesn't hide a holiday inside it).
      intervals = rows.group_by { |row| row.values_at('from_status_id', 'to_status_id', 'from_status_date', 'to_status_date') }.map { |_key, day_rows|
        { days: day_rows, total: day_rows.sum { |row| row['minutes_counted'].to_i } }
      }
      [sla_type, intervals] if intervals.any?
    }.to_h
    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  # Build the context menu for one or multiple SLA caches.
  def context_menu
    if @sla_caches.size == 1
      @sla_cache = @sla_caches.first
    end
    can_show    = @sla_caches.detect { |c| !c.visible? }.nil?
    can_refresh = @sla_caches.all?(&:deletable?)
    can_delete  = @sla_caches.detect { |c| !c.deletable? }.nil?
    @can = { show: can_show, refresh: can_refresh, delete: can_delete }

    @back = back_url
    @sla_cache_ids, @safe_attributes, @selected = [], [], {}

    @sla_caches.each do |e|
      @sla_cache_ids << e.id
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

  # Reading cache data requires :view_sla (enforced by authorize_global and
  # visible?). Mutating it requires :manage_sla on every affected project.
  # Only an administrator may purge all projects at once.
  def authorize_cache_management
    return if User.current.admin?

    projects = if action_name == 'purge'
                 [@project].compact
               else
                 @sla_caches.map(&:project).uniq
               end

    raise Unauthorized if projects.empty?
    raise Unauthorized unless projects.all? { |project| User.current.allowed_to?(:manage_sla, project) }
    raise Unauthorized if @project && projects.any? { |project| project != @project }
  end

  # Find a single SLA cache and check visibility.
  def find_sla_cache
    @sla_cache = SlaCache.find(params[:id])
    raise Unauthorized unless @sla_cache.visible?
    raise ActiveRecord::RecordNotFound if @sla_cache.nil?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Find a collection of SLA caches (used in bulk actions).
  def find_sla_caches
    params[:ids] = params[:id].nil? ? params[:ids] : [params[:id]]
    @sla_caches  = SlaCache.find(params[:ids]).to_a
    @sla_cache   = @sla_caches.first if @sla_caches.count == 1
    raise Unauthorized unless @sla_caches.all?(&:visible?)
    raise ActiveRecord::RecordNotFound if @sla_caches.empty?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Find the issue to explain (by issue id, not sla_cache id — explain must
  # work even when the issue has no SlaCache row yet).
  def find_issue_for_explain
    @issue = Issue.visible.find(params[:id])
    @project = @issue.project
    raise Unauthorized unless User.current.allowed_to?(:manage_sla, @project)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Force users through project context for access control (optional).
  # If enabled, this restricts which routes can be used to access SLA caches,
  # depending on the current user and project.
  #
  # def check_routing_users
  #   unless User.current.admin? && @project.nil?
  #     valid_routes = []
  #     valid_routes += [
  #       context_menu_project_sla_caches_path(@project),
  #       purge_project_sla_caches_path(@project),
  #       purge_project_sla_caches_path(@project)+".xml",
  #       purge_project_sla_caches_path(@project)+".json",
  #       project_sla_caches_path(@project),
  #       project_sla_caches_path(@project)+".xml",
  #       project_sla_caches_path(@project)+".json",
  #     ] unless @project.nil?
  #     valid_routes += [
  #       project_sla_cache_path(@project,@sla_cache),
  #       project_sla_cache_path(@project,@sla_cache)+".xml",
  #       project_sla_cache_path(@project,@sla_cache)+".json",
  #       refresh_project_sla_cache_path(@project,@sla_cache),
  #       refresh_project_sla_cache_path(@project,@sla_cache)+".xml",
  #       refresh_project_sla_cache_path(@project,@sla_cache)+".json",
  #     ] unless @project.nil? || @sla_cache.nil?
  #     raise Unauthorized unless valid_routes.include?(request.path)
  #   end
  # end  

  # Retrieve the default SlaCacheQuery if no query is selected by the user.
  def retrieve_default_query(use_session)
    return if params[:query_id].present?
    return if api_request?
    return if params[:set_filter]

    if params[:without_default].present?
      params[:set_filter] = 1
      return
    end

    if !params[:set_filter] && use_session && session[:sla_cache_query]
      query_id, project_id = session[:sla_cache_query].values_at(:id, :project_id)
      return if SlaCacheQuery.where(id: query_id).exists? && project_id == @project&.id
    end

    if default_query = SlaCacheQuery.default(project: @project)
      params[:query_id] = default_query.id
    end
  end  

  # Returns the SlaCacheQuery scope for index and report actions.
  def sla_cache_scope(options = {})
    @query.results_scope(options)
  end

  # Initialize or restore the SlaCacheQuery from params or session.
  def retrieve_sla_cache_query
    retrieve_query(SlaCacheQuery, false, :defaults => @default_columns_names)
  end

  # Handle query errors, and reset stored SLA cache query session key.
  def query_error(exception)
    session.delete(:sla_cache_query)
    super
  end

end
