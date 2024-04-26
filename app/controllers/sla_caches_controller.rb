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
  
  unloadable

  accept_api_auth :index, :show, :refresh, :destroy
  before_action :require_admin, except: [:show,:refresh]
  before_action :authorize_global
  
  before_action :find_sla_cache, only: [:show]
  before_action :find_sla_caches, only: [:context_menu, :refresh, :destroy]

  rescue_from Query::StatementInvalid, :with => :query_statement_invalid
  rescue_from Query::QueryError, :with => :query_error
  
  helper :context_menus
  helper :projects
  helper :issues
  helper :queries
  include QueriesHelper
  helper :sla_caches

  def index
    #use_session = !request.format.csv?
    #retrieve_default_query(use_session) 
    retrieve_query(Queries::SlaCacheQuery)

    @entity_count = @query.sla_caches.count
    @entity_pages = Paginator.new @entity_count, per_page_option, params['page']
    @entities = @query.sla_caches(offset: @entity_pages.offset, limit: @entity_pages.per_page)
    respond_to do |format|
      format.html do
      end
      format.api do
        @offset, @limit = api_offset_and_limit
      end
    end      
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def show
    @sla_cache.reload.refresh
    respond_to do |format|
      format.html do
        redirect_back_or_default sla_caches_path        
      end
      format.api do
        @sla_cache_spents = @sla_cache.sla_cache_spents.to_a
      end
    end
  end

  def refresh
    @sla_caches.each do |sla_cache|
      begin
        sla_cache.reload.refresh
      rescue ::ActiveRecord::RecordNotFound
      end
    end  
    respond_to do |format|
      format.html do
        flash[:notice] = l(:notice_successful_refresh)
        redirect_back_or_default sla_caches_path
        end
      format.api {render_api_ok}
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
        redirect_back_or_default sla_caches_path
      end
      format.api {render_api_ok}
    end
  end

  def context_menu
    if @sla_caches.size == 1
      @sla_cache = @sla_caches.first
    end
    can_show = @sla_caches.detect{|c| !c.visible?}.nil?
    can_delete = @sla_caches.detect{|c| !c.deletable?}.nil?
    @can = {show: can_show, delete: can_delete}
    @back = back_url
    @sla_cache_ids, @safe_attributes, @selected = [], [], {}
    @sla_caches.each do |e|
      @sla_cache_ids << e.id
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

  def query_error(exception)
    #session.delete(:sla_cache_query)
    super
  end

  # def retrieve_default_query(use_session)
  #   return if params[:query_id].present?
  #   return if api_request?
  #   return if params[:set_filter]

  #   if params[:without_default].present?
  #     params[:set_filter] = 1
  #     return
  #   end
  #   if !params[:set_filter] && use_session && session[:sla_cache_query]
  #     query_id, project_id = session[:sla_cache_query].values_at(:id, :project_id)
  #     return if SlaCacheQuery.where(id: query_id).exists? && project_id == @project&.id
  #   end
  #   if default_query = SlaCacheQuery.default(project: @project)
  #     params[:query_id] = default_query.id
  #   end
  # end

  def find_sla_cache
    @sla_cache = SlaCache.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_sla_caches
    params[:ids] = params[:id].nil? ? params[:ids] : [params[:id]] 
    @sla_caches = SlaCache.find(params[:ids])
    @sla_cache = @sla_caches.first if @sla_caches.count == 1
    raise ActiveRecord::RecordNotFound if @sla_caches.empty?
    raise Unauthorized unless @sla_caches.all?(&:visible?)
  rescue ActiveRecord::RecordNotFound
    render_404
  end


end