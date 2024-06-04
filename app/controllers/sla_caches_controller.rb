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

class SlaCachesController < ApplicationController
  default_search_scope :sla_caches
  
  unloadable

  accept_api_auth :index, :show, :refresh, :destroy, :purge

  before_action :require_admin, except: [ :index, :show, :refresh, :destroy, :context_menu ]
  before_action :authorize_global
    
  before_action :find_sla_cache, only: [ :show ]
  before_action :find_sla_caches, only: [ :refresh, :destroy, :context_menu ]

  before_action :find_optional_project, :only => [ :index, :show, :refresh, :destroy, :purge ]
  # before_action :check_routing_users, :only => [ :index, :show, :refresh, :destroy, :purge ]
  
  rescue_from Query::StatementInvalid, :with => :query_statement_invalid
  rescue_from Query::QueryError, :with => :query_error
  
  helper :sla_caches
  helper :context_menus
  
  helper :queries
  include QueriesHelper

  helper Queries::SlaCachesQueriesHelper
  include Queries::SlaCachesQueriesHelper

  def index
    use_session = !request.format.csv?
    retrieve_default_query(use_session) 
    retrieve_query(Queries::SlaCacheQuery,use_session)

    scope = sla_cache_scope.
      preload(:issue => [:project, :tracker, :status, :priority]).
      preload(:project)

    respond_to do |format|
      format.html do
        @entity_count = scope.count
        @entity_pages = Paginator.new @entity_count, per_page_option, params['page']
        @entities = scope.offset(@entity_pages.offset).limit(@entity_pages.per_page).to_a
        render :layout => !request.xhr?
      end
      format.api do
        @entity_count = scope.count
        @offset, @limit = api_offset_and_limit
        @entities = scope.offset(@offset).limit(@limit).to_a
      end
      format.atom do
        entities = scope.limit(Setting.feeds_limit.to_i).reorder("#{SlaCache.table_name}.updated_on DESC").to_a
        render_feed(entities, :title => l(:label_sla_cache))
      end
      format.csv do
        # Export all entities
        @entities = scope.to_a
        send_data(query_to_csv(@entities, @query, params), :type => 'text/csv; header=present', :filename => "#{filename_for_export(@query, 'timelog')}.csv")
      end
    end      
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def show
    respond_to do |format|
      format.html { redirect_back_or_default sla_caches_path }
      format.api { @sla_cache_spents = @sla_cache.sla_cache_spents.to_a }
    end
  end

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

  def context_menu
    if @sla_caches.size == 1
      @sla_cache = @sla_caches.first
    end
    can_show = User.current.admin?
    can_refresh = @sla_caches.detect{|c| !c.visible?}.nil?
    can_delete = @sla_caches.detect{|c| !c.deletable?}.nil?
    @can = {show: can_show, refresh: can_refresh, delete: can_delete}
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

  def find_sla_cache
    @sla_cache = SlaCache.find(params[:id])
    raise Unauthorized unless @sla_cache.visible?
    raise ActiveRecord::RecordNotFound if @sla_cache.nil?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_sla_caches
    params[:ids] = params[:id].nil? ? params[:ids] : [params[:id]] 
    @sla_caches = SlaCache.find(params[:ids]).to_a
    @sla_cache = @sla_caches.first if @sla_caches.count == 1
    raise Unauthorized unless @sla_caches.all?(&:visible?)
    raise ActiveRecord::RecordNotFound if @sla_caches.empty?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Force users through projects
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
      return if Queries::SlaCacheQuery.where(id: query_id).exists? && project_id == @project&.id
    end
    if default_query = Queries::SlaCacheQuery.default(project: @project)
      params[:query_id] = default_query.id
    end
  end  

  # Returns the SlaCache scope for index and report actions
  def sla_cache_scope(options={})
    @query.results_scope(options)
  end

  def retrieve_sla_cache_query
    retrieve_query(SlaCacheQuery, false, :defaults => @default_columns_names)
  end

  def query_error(exception)
    session.delete(:sla_cache_query)
    super
  end

end