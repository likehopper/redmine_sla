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

class SlaLevelsController < ApplicationController

  unloadable

  before_action :require_admin, except: [:show]

  before_action :find_sla_level, only: [:show, :edit, :update]
  before_action :find_sla_levels, only: [:context_menu, :destroy]

  before_action :authorize_global

  helper :sla_levels
  helper :context_menus
  helper :queries
  include QueriesHelper

  def index
    retrieve_query(Queries::SlaLevelQuery) 
    @entity_count = @query.sla_levels.count
    @entity_pages = Paginator.new @entity_count, per_page_option, params['page']
    @entities = @query.sla_levels(offset: @entity_pages.offset, limit: @entity_pages.per_page) 
  end

  def new
    @sla_level = SlaLevel.new
    @sla_level.safe_attributes = params[:sla_level]
  end

  def create
    @sla_level = SlaLevel.new
    @sla_level.safe_attributes = params[:sla_level]
    if @sla_level.save
      flash[:notice] = l(:notice_successful_create)
      redirect_back_or_default sla_levels_path
    else
      render :new
    end
  end

  def update
    @sla_level.safe_attributes = params[:sla_level]
    if @sla_level.save
      flash[:notice] = l(:notice_successful_update)
      redirect_back_or_default sla_levels_path
    else
      render :edit
    end
  end

  def destroy
    @sla_levels.each(&:destroy)
    flash[:notice] = l(:notice_successful_delete)
    redirect_back_or_default sla_levels_path
  end

  def context_menu
    Rails.logger.warn "======>>> sla_level->context_menu() <<<====== "
    if @sla_levels.size == 1
      @sla_level = @sla_levels.first
    end
    can_edit = @sla_levels.detect{|c| !c.editable?}.nil?
    can_delete = @sla_levels.detect{|c| !c.deletable?}.nil?
    @can = {edit: can_edit, delete: can_delete}
    @back = back_url
    @sla_level_ids, @safe_attributes, @selected = [], [], {}
    @sla_levels.each do |e|
      @sla_level_ids << e.id
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

  def find_sla_level
    @sla_level = SlaLevel.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_sla_levels
    @sla_levels = SlaLevel.visible.where(id: (params[:id]||params[:ids])).to_a
    raise ActiveRecord::RecordNotFound if @sla_levels.empty?
    #raise Unauthorized unless @sla_levels.all?(&:visible?)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end