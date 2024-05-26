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

  unloadable

  accept_api_auth :index

  before_action :authorize_global

  before_action :find_project_tracker, :only => [:update, :edit, :destroy]
  before_action :find_project, :only => [ :index, :create, :edit, :update, :destroy]

  helper :sla_project_trackers
  helper :queries
  include QueriesHelper

  def index
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

  def new
    @sla_project_tracker = SlaProjectTracker.new
  end

  def create
    @sla_project_tracker = SlaProjectTracker.new
    @sla_project_tracker.safe_attributes = params[:sla_project_tracker]
    @sla_project_tracker.project = @project
    if @sla_project_tracker.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to_project
    else
      render :action => 'new', :layout => !request.xhr?
    end
  end

  def update
    @sla_project_tracker.safe_attributes = params[:sla_project_tracker]
    @sla_project_tracker.project = @project
    if @sla_project_tracker.save
      flash[:notice] = l(:notice_successful_update)
      flash[:warning] = l('label_sla_warning',changes: 'update') if @sla_project_tracker.previous_changes.any?
      redirect_to_project
    else
      render :action => 'edit'
    end
  end

  def destroy
    @sla_project_tracker.destroy
    flash[:notice] = l(:notice_successful_delete)
    flash[:warning] = l('label_sla_warning',changes: 'destroy')
    redirect_to_project
  end

private

  def redirect_to_project
    redirect_to settings_project_path(@project, :tab => 'slas')
  end

  def find_project_tracker
    @sla_project_tracker = SlaProjectTracker.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end  

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end