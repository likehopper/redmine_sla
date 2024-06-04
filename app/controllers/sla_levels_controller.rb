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

  accept_api_auth :index, :create, :show, :update, :destroy
  
  before_action :require_admin, except: [:show]
  before_action :authorize_global

  before_action :find_sla_level, only: [:show, :edit, :update, :nested]
  before_action :find_sla_levels, only: [ :destroy, :context_menu ]

  helper :sla_levels
  helper :context_menus

  helper :queries
  include QueriesHelper

  helper Queries::SlaLevelsQueriesHelper
  include Queries::SlaLevelsQueriesHelper 

  def index
    retrieve_query(Queries::SlaLevelQuery) 
    @entity_count = @query.sla_levels.count
    @entity_pages = Paginator.new @entity_count, per_page_option, params['page']
    @entities = @query.sla_levels(offset: @entity_pages.offset, limit: @entity_pages.per_page) 
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
  #     format.html do
  #       end
  #     format.api
  #   end
  # end

  def new
    @sla_level = SlaLevel.new
    @sla_level.safe_attributes = params[:sla_level]
  end

  def create
    @sla_level = SlaLevel.new
    @sla_level.safe_attributes = params[:sla_level]
    if @sla_level.save
      respond_to do |format|
        format.html do
          flash[:notice] = l(:notice_successful_create)
          redirect_back_or_default sla_levels_path
        end
        format.api do
          render :action => 'show', :status => :created,
            :location => sla_level_url(@sla_level)
        end
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.api { render_validation_errors(@sla_level) }
      end
    end
  end

  def update
    @sla_level.safe_attributes = params[:sla_level]
    if ! params[:sla_level][:sla_level_terms_attributes].nil?
      @sla_level.update(sla_level_params)
    end
    if @sla_level.custom_field_id_changed?
      flash[:warning] = l('sla_label.sla_level.purge')
    end    
    if @sla_level.save
      respond_to do |format|
        format.html do 
          flash[:notice] = l(:notice_successful_update)
          redirect_back_or_default sla_levels_path
        end
        format.api { render_api_ok }
      end
    else
      respond_to do |format|
        format.html do
          if params[:sla_level][:sla_level_terms_attributes].nil?
            render :action => 'edit'
          else
            render :action => 'nested'
          end
        end 
        format.api { render_validation_errors(@sla_level) }
      end
    end
  end

  def nested
    respond_to do |format|
      format.html do
      end
    end
  end  

  def destroy
    @sla_levels.each do |sla_level|
      begin
        sla_level.reload.destroy
      rescue ::ActiveRecord::RecordNotFound
      end
    end
    respond_to do |format|
      format.html do
        flash[:notice] = l(:notice_successful_delete)
        redirect_back_or_default sla_levels_path
      end
      format.api { render_api_ok }
    end
  end

  def context_menu
    if @sla_levels.size == 1
      @sla_level = @sla_levels.first
    end
    can_show = @sla_levels.detect{|c| !c.visible?}.nil?
    can_edit = @sla_levels.detect{|c| !c.editable?}.nil?
    can_delete = @sla_levels.detect{|c| !c.deletable?}.nil?
    @can = {show: can_show, edit: can_edit, delete: can_delete}
    @back = back_url
    @sla_level_ids, @safe_attributes, @selected = [], [], {}
    @sla_levels.each do |e|
      @sla_level_ids << e.id
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

  def find_sla_level
    @sla_level = SlaLevel.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_sla_levels
    @sla_levels = SlaLevel.visible.where(id: (params[:id] || params[:ids])).to_a
    raise ActiveRecord::RecordNotFound if @sla_levels.empty?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def sla_level_params
    params[:sla_level][:sla_level_terms_attributes].transform_values! do |value|
      if value[:term].empty?
        value[:_destroy] = true
        value.delete(:term)
      else
        value[:_destroy] = false
      end
      value
    end
    params.require(:sla_level).permit(sla_level_terms_attributes: SlaLevelTerm.attribute_names.map(&:to_sym).push(:_destroy) )
  end
  
end