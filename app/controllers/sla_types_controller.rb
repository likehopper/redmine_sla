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

class SlaTypesController < ApplicationController

  unloadable

  accept_api_auth :index
  before_action :require_admin
  before_action :authorize_global

  before_action :find_sla_type, only: [:show, :edit, :update]
  before_action :find_sla_types, only: [:context_menu, :destroy]

  helper :sla_types
  helper :context_menus
  helper :queries
  include QueriesHelper

  def index
    retrieve_query(Queries::SlaTypeQuery) 
    @entity_count = @query.sla_types.count
    @entity_pages = Paginator.new @entity_count, per_page_option, params['page']
    @entities = @query.sla_types(offset: @entity_pages.offset, limit: @entity_pages.per_page) 
    respond_to do |format|
      format.html do
      end
      format.api do
        @offset, @limit = api_offset_and_limit
      end
    end    
  end

  def new
    @sla_type = SlaType.new
    @sla_type.safe_attributes = params[:sla_type]
  end

  def create
    @sla_type = SlaType.new
    @sla_type.safe_attributes = params[:sla_type]
    if @sla_type.save
      flash[:notice] = l(:notice_successful_create)
      redirect_back_or_default sla_types_path
    else
      render :new
    end
  end

  def update
    @sla_type.safe_attributes = params[:sla_type]
    if @sla_type.save
      flash[:notice] = l(:notice_successful_update)
      redirect_back_or_default sla_types_path
    else
      render :edit
    end
  end

  def destroy
    @sla_types.each(&:destroy)
    flash[:notice] = l(:notice_successful_delete)
    redirect_back_or_default sla_types_path
  end

  def context_menu
    if @sla_types.size == 1
      @sla_type = @sla_types.first
    end
    can_edit = @sla_types.detect{|c| !c.editable?}.nil?
    can_delete = @sla_types.detect{|c| !c.deletable?}.nil?
    @can = {edit: can_edit, delete: can_delete}
    @back = back_url
    @sla_type_ids, @safe_attributes, @selected = [], [], {}
    @sla_types.each do |e|
      @sla_type_ids << e.id
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

  def find_sla_type
    @sla_type = SlaType.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_sla_types
    @sla_types = SlaType.visible.where(id: (params[:id] || params[:ids])).to_a
    #@sla_type = @sla_types.first if @sla_types.count == 1
    raise ActiveRecord::RecordNotFound if @sla_types.empty?
    #raise Unauthorized unless @sla_types.all?(&:visible?)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end