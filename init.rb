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

require "redmine"

require "nested_form"
require "chronic"
require "chronic_duration"
require "composite_primary_keys"

Redmine::Plugin.register :redmine_sla do

  name 'Redmine SLA'
  author 'LikeHopper'
  description 'This is a plugin for Redmine to manage SLA'
  version RedmineSla::Version
  author_url 'https://github.com/likehopper'
  url 'https://github.com/likehopper/redmine_sla'

  requires_redmine :version_or_higher => '4.0'

  # Global Settings definition
  settings(
    # Default global value for all projects
    :default => {   
      'sla_log_level' => '1',
      'sla_cache_ttl' => '1',
      'sla_time_zone' => 'Etc/UTC',
      'sla_display'   => 'bar',
    },
    # Ref. file "app/views/sla_settings_plugin/_sla_settings_plugin.html.erb" 
    :partial => 'sla_settings_plugin/sla_settings_plugin'
  )

  # Add entry in administration menu
  menu :admin_menu, :sla,
    { controller: 'slas', action: 'index'},
    caption: :sla_label_global_settings, html: { class: 'icon redmine-sla' }, public: true

  # Project Permission Definition
  project_module :sla do
    permission :view_sla, {
      :issue => :index,
      :sla_calendars => :show,
      :sla_levels => :show
    }, :require => :member
    permission :manage_sla, {
      projects: :settings,
      sla_project_trackers: [ :new, :create, :edit, :update, :edit, :destroy ]
    }, :require => :member
  end
       
end

RedmineApp::Application.config.after_initialize do

  require_dependency 'projects_controller'
  ProjectsController.helper(RedmineSla::Patches::ProjectsHelperPatch)
  
  unless Issue.included_modules.include? RedmineSla::Patches::IssuePatch
    Issue.send(:include, RedmineSla::Patches::IssuePatch)
  end

  unless TimeEntry.included_modules.include? RedmineSla::Patches::TimeEntryPatch
    TimeEntry.send(:include, RedmineSla::Patches::TimeEntryPatch)
  end

  if (ActiveRecord::Base.connection.tables.include?('queries') rescue false) &&
    # Seaarch on Redmine's issues
    IssueQuery.included_modules.exclude?(RedmineSla::Patches::IssueQueryPatch)
    IssueQuery.send(:include, RedmineSla::Patches::IssueQueryPatch)
    # Search on Redmine's time entry
    TimeEntryQuery.included_modules.exclude?(RedmineSla::Patches::TimeEntryQueryPatch)
    TimeEntryQuery.send(:include, RedmineSla::Patches::TimeEntryQueryPatch)
  end  

end  