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

class SlaIssuesController < ApplicationController

  unloadable

  accept_api_auth :index

  before_action :find_project, :only => [ :index, :destroy]

  helper :sla_issues
  helper :queries
  include QueriesHelper

  def index
    Rails.logger.info "==>> SlaIssuesController ==> Index"
  end

  def show
    Rails.logger.info "==>> SlaIssuesController ==> Show"  
  end

  def update
    Rails.logger.info "==>> SlaIssuesController ==> update"  
  end

  def destroy
    Rails.logger.info "==>> SlaIssuesController ==> destroy"  
  end

private

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_issue
    @issue = Issue.find(params[:issue_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end