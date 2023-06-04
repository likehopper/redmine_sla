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

  before_action :find_project_tracker, :only => [:update, :edit, :destroy]
  before_action :find_project, :only => [:create, :edit, :update, :destroy]

  def new
    @sla_project_tracker = SlaProjectTracker.new
  end

  def create
    @sla_project_tracker = SlaProjectTracker.new
    @sla_project_tracker.safe_attributes = params[:sla_project_tracker]
    #@project = Project.find(params[:project_id])
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
    #@project = Project.find(params[:project_id])
    @sla_project_tracker.project = @project
    if @sla_project_tracker.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to_project
    else
      render :action => 'edit'
    end
  end

  def destroy
    @sla_project_tracker.destroy
    flash[:notice] = l(:notice_successful_delete)
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