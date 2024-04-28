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

class SlaCacheSpentsController < ApplicationController

  unloadable

  accept_api_auth :index, :show, :refresh, :destroy
  before_action :require_admin, except: [:show,:refresh]
  before_action :authorize_global
  
  before_action :find_sla_cache_spent, only: [:show]
  before_action :find_sla_cache_spents, only: [:context_menu, :refresh, :destroy]

  helper :context_menus
  #helper :sla_issues
  helper :queries
  include QueriesHelper

  def index
    retrieve_query(Queries::SlaCacheSpentQuery) 
    @entity_count = @query.sla_cache_spents.count
    @entity_pages = Paginator.new @entity_count, per_page_option, params['page']
    @entities = @query.sla_cache_spents(offset: @entity_pages.offset, limit: @entity_pages.per_page)
    respond_to do |format|
      format.html do
      end
      format.api do
        @offset, @limit = api_offset_and_limit
      end
    end      
  end

  def show
    respond_to do |format|
      format.html do
        redirect_back_or_default sla_cache_spents_path
      end      
      format.api do
        @sla_cache_spent.reload.refresh
      end
    end
  end

  def refresh
    @sla_cache_spents.each do |sla_cache_spent|
      begin
        sla_cache_spent.reload.refresh
      rescue ::ActiveRecord::RecordNotFound
      end
    end  
    respond_to do |format|
      format.html do
        flash[:notice] = l(:notice_successful_refresh)
        redirect_back_or_default sla_cache_spents_path
        end
      format.api {render_api_ok}
    end    
  end

  def purge
    SlaCacheSpent.purge 
    respond_to do |format|
      format.html do
        flash[:notice] = l(:notice_successful_purge)
        redirect_back_or_default sla_cache_spents_path
        end
      format.api {render_api_ok}
    end    
  end
  
  def destroy
    @sla_cache_spents.each do |sla_cache_spent|
      begin
        sla_cache_spent.reload.destroy
      rescue ::ActiveRecord::RecordNotFound
      end
    end
    respond_to do |format|
      format.html do
        flash[:notice] = l(:notice_successful_delete)
        redirect_back_or_default sla_cache_spents_path
      end
      format.api {render_api_ok}
    end
  end

  def context_menu
    if @sla_cache_spents.size == 1
      @sla_cache_spent = @sla_cache_spents.first
    end
    can_show = @sla_cache_spents.detect{|c| !c.visible?}.nil?
    can_delete = @sla_cache_spents.detect{|c| !c.deletable?}.nil?
    @can = {show: can_show, delete: can_delete}
    @back = back_url
    @sla_cache_spent_ids, @safe_attributes, @selected = [], [], {}
    @sla_cache_spents.each do |e|
      @sla_cache_spent_ids << e.id
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

  def find_sla_cache_spent
    @sla_cache_spent = SlaCacheSpent.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_sla_cache_spents
    params[:ids] = params[:id].nil? ? params[:ids] : [params[:id]] 
    @sla_cache_spents = SlaCacheSpent.find(params[:ids])
    @sla_cache_spent = @sla_cache_spents.first if @sla_cache_spents.count == 1
    raise ActiveRecord::RecordNotFound if @sla_cache_spents.empty?
    raise Unauthorized unless @sla_cache_spents.all?(&:visible?)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end