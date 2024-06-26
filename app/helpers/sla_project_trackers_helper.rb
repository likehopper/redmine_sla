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

module SlaProjectTrackersHelper

  # Generates a link to a sla_project_tracker with id
  def link_to_sla_project_tracker_id(sla_project_tracker)
    link_to sla_project_tracker.id, _sla_project_trackers_path(sla_project_tracker.project)
    # link_to sla_project_tracker.id, settings_project_path(sla_project_tracker.project,tab: :sla)
  end  

  def _sla_project_trackers_path(project=nil, *args)
    #options = args.extract_options!
    Rails.logger.debug "Arguments: back_url = #{back_url}"
    #Rails.logger.debug "Arguments: options = #{options.inspect}"
    if project
    #  if options.empty? && options[:tab].nil?
        Rails.logger.debug "Arguments: project_sla_project_trackers_path"
        project_sla_project_trackers_path(project, *args)
    #  else
    #    Rails.logger.debug "Arguments: settings_project_path"
    #    settings_project_path(project, *args)
    #  end
    else
      Rails.logger.debug "Arguments: sla_project_trackers_path"
      sla_project_trackers_path(*args)
    end
  end

  def _sla_project_tracker_path(project=nil, *args)
    project.nil? ? sla_project_tracker_path(*args) : project_sla_project_tracker_path(project, *args)
  end

  def _new_sla_project_tracker_path(project=nil, *args)
    project.nil? ? new_sla_project_tracker_path(*args) : new_project_sla_project_tracker_path(project, *args)
  end

  def _edit_sla_project_tracker_path(project=nil, *args)
    project.nil? ? edit_sla_project_tracker_path(*args) : edit_project_sla_project_tracker_path(project, *args)
  end

end