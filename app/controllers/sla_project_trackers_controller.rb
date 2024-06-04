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

class SlaProjectTrackersController < ApplicationController
  default_search_scope :sla_project_trackers
  
  unloadable

  accept_api_auth :index, :create, :update, :destroy

  before_action :authorize_global 

  before_action :find_optional_project, :only => [ :index, :show, :new, :create, :edit, :update, :destroy, :context_menu ]
  before_action :find_project_tracker, :only => [ :show, :edit, :update ]
  before_action :find_project_trackers, only: [ :destroy, :context_menu ]

  rescue_from Query::StatementInvalid, :with => :query_statement_invalid
  rescue_from Query::QueryError, :with => :query_error

  helper :sla_project_trackers

  helper :queries
  include QueriesHelper

  helper :context_menus

  def index
    use_session = !request.format.csv?
    retrieve_default_query(use_session) 
    retrieve_query(Queries::SlaProjectTrackerQuery) 

    @entity_count = @query.sla_project_trackers.count
    @entity_pages = Paginator.new @entity_count, per_page_option, params['page']
    @entities = @query.sla_project_trackers(offset: @entity_pages.offset, limit: @entity_pages.per_page)
    respond_to do |format|
      format.html do
      end
      format.api do
        @offset, @limit = api_offset_and_limit
      end
    end      
  end

  # def show
  #   respond_to do |format|
  #     format.html do end
  #     format.api do end
  #   end
  # end  

  def new
    @sla_project_tracker = SlaProjectTracker.new
  end

  def create
    @sla_project_tracker = SlaProjectTracker.new
    @sla_project_tracker.safe_attributes = params[:sla_project_tracker]
    @sla_project_tracker.project = @project unless @project.nil?
    if @sla_project_tracker.save
      respond_to do |format|
        format.html do
          flash[:notice] = l(:notice_successful_create)
          redirect_back_or_default ( @project.nil? ? sla_project_trackers_path : settings_project_path(@project,tab: :sla) )
        end
        format.api do
          render :action => 'show', :status => :created,
            :location => sla_project_tracker_url(@sla_project_tracker)
        end
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.api { render_validation_errors(@sla_project_tracker) }
      end
    end
  end

  def update
    @sla_project_tracker.safe_attributes = params[:sla_project_tracker]
    @sla_project_tracker.project = @project unless @project.nil?
    if @sla_project_tracker.save
      respond_to do |format|
        format.html do
          flash[:notice] = l(:notice_successful_update)
          flash[:warning] = l('label_sla_warning',changes: 'update') if @sla_project_tracker.previous_changes.any?
          redirect_back_or_default ( @project.nil? ? sla_project_trackers_path : settings_project_path(@project,tab: :sla) )
        end
        format.api { render_api_ok }
      end    
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
        format.api { render_validation_errors(@sla_project_tracker) }
      end


    end
  end

  def destroy
    @sla_project_trackers.each do |sla_project_tracker|
      begin
        sla_project_tracker.reload.destroy
      rescue ::ActiveRecord::RecordNotFound
      end
    end
    respond_to do |format|
      format.html do
        flash[:notice] = l(:notice_successful_delete)
        flash[:warning] = l('label_sla_warning',changes: 'destroy')
        Rails.logger.debug "Arguments: controller @project = #{@project}"
        Rails.logger.debug "Arguments: controller back_url = #{back_url}"
        Rails.logger.debug "Arguments: controller @back = #{@back}"
        redirect_back_or_default ( @project.nil? ? sla_project_trackers_path : settings_project_path(@project,tab: :sla) )
        # redirect_to
      end
      format.api { render_api_ok }
    end
  end

  def context_menu
    if @sla_project_trackers.size == 1
      @sla_project_tracker = @sla_project_trackers.first
    end
    can_show = @sla_project_trackers.detect{|c| !c.visible?}.nil?
    can_edit = @sla_project_trackers.detect{|c| !c.editable?}.nil?
    can_delete = @sla_project_trackers.detect{|c| !c.deletable?}.nil?
    @can = {show: can_show, edit: can_edit, delete: can_delete}
    @back = back_url
    @sla_project_tracker_ids, @safe_attributes, @selected = [], [], {}
    @sla_project_trackers.each do |e|
      @sla_project_tracker_ids << e.id
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

  def find_project_tracker
    @sla_project_tracker = SlaProjectTracker.visible.find(params[:id])
    raise ActiveRecord::RecordNotFound if @sla_project_tracker.nil?
  rescue ActiveRecord::RecordNotFound
    render_404
  end  

  def find_project_trackers
    params[:ids] = params[:id].nil? ? params[:ids] : [params[:id]] 
    @sla_project_trackers = SlaProjectTracker.visible.find(params[:ids])    
    @sla_project_tracker = @sla_project_trackers.first if @sla_project_trackers.count == 1
    #raise Unauthorized unless @sla_project_trackers.all?(&:visible?)
    raise ActiveRecord::RecordNotFound if @sla_project_trackers.empty?
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
    if !params[:set_filter] && use_session && session[:sla_project_tracker_query]
      query_id, project_id = session[:sla_project_tracker_query].values_at(:id, :project_id)
      return if Queries::SlaProjectTrackerQuery.where(id: query_id).exists? && project_id == @project&.id
    end
    if default_query = Queries::SlaProjectTrackerQuery.default(project: @project)
      params[:query_id] = default_query.id
    end
  end    

  # Returns the SlaProjectTracker scope for index and report actions
  def sla_project_tracker_scope(options={})
    @query.results_scope(options)
  end

  def retrieve_sla_project_tracker_query
    retrieve_query(SlaProjectTrackerQuery, false, :defaults => @default_columns_names)
  end

  def query_error(exception)
    session.delete(:sla_project_tracker_query)
    super
  end  

end