# frozen_string_literal: true

# File: redmine_sla/init.rb
# Purpose:
#   Main initializer for the Redmine SLA plugin. Declares plugin metadata,
#   loads dependencies, registers settings, menus, permissions, and injects
#   runtime patches into core Redmine classes after initialization.
#
# Redmine SLA - Redmine Plugin
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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

require "redmine"

# Plugin dependencies
require "nested_form"
require "chronic"
require "chronic_duration"

# Load custom pluralization rules (e.g., "sla_cache" → "sla_caches")
require_relative "config/initializers/inflections.rb"

# Plugin registration block
Redmine::Plugin.register :redmine_sla do

  name 'Redmine SLA'
  author 'LikeHopper'
  description 'This is a plugin for Redmine to manage SLA'
  version RedmineSla::Version
  author_url 'https://github.com/likehopper'
  url 'https://github.com/likehopper/redmine_sla'

  # Minimum Redmine version required
  requires_redmine version_or_higher: '4.0'

  # Global plugin settings (default values + configuration partial)
  settings(
    default: {
      'sla_log_level' => '1',
      'sla_cache_ttl' => '1',
      'sla_time_zone' => 'Etc/UTC',
      'sla_display'   => 'bar'
    },
    # Settings UI partial
    partial: 'sla_settings_plugin/sla_settings_plugin'
  )

  # Add entry in Redmine's administration menu
  menu :admin_menu, :redmine_sla,
    { controller: 'slas', action: 'index' },
    html: { class: 'icon redmine-sla' },
    caption: :sla_label_global_settings,
    public: false

  # Add entry in the project-specific menu
  menu :project_menu, :redmine_sla,
    { controller: 'sla_caches', action: 'index' },
    caption: :sla_label_abbreviation,
    param: :project_id

  # Define permissions
  project_module :sla do

    # Read-only SLA access
    permission :view_sla, {
      sla_levels:        [:show],
      sla_calendars:     [:show],
      sla_caches:        [:index, :show, :refresh, :context_menu],
      sla_cache_spents:  [:index, :show, :refresh, :context_menu]
    }, require: :member

    # Full SLA management
    permission :manage_sla, {
      sla_project_trackers: [:index, :new, :create, :edit, :update, :destroy, :context_menu],
      sla_cache_spents:     [:index, :show, :refresh, :destroy, :purge, :context_menu],
      sla_caches:           [:index, :show, :refresh, :destroy, :purge, :context_menu]
    }, require: :member
  end

end

# After Redmine bootstrap, extend core classes with SLA patches
RedmineApp::Application.config.after_initialize do

  # Load helper modules ( to display respect boolean in lists )
  ActionView::Base.send(:include, RedmineSla::Helpers::SlaRenderingHelper)

  # Adds Project-level SLA helpers
  unless ProjectsController.included_modules.include? RedmineSla::Patches::ProjectsHelperPatch
    ProjectsController.helper(RedmineSla::Patches::ProjectsHelperPatch)
  end

  # Adds SLA display/filter support in issues#index and time_entries#index
  unless QueriesHelper.included_modules.include? RedmineSla::Patches::QueriesHelperPatch
    QueriesHelper.send(:include, RedmineSla::Patches::QueriesHelperPatch)
  end

  # Extend TimeEntry with SLA calculation helpers
  unless TimeEntry.included_modules.include? RedmineSla::Patches::TimeEntryPatch
    TimeEntry.send(:include, RedmineSla::Patches::TimeEntryPatch)
  end

  # Extend IssueCustomField to render SLA custom fields correctly
  unless IssueCustomField.included_modules.include? RedmineSla::Patches::IssueCustomFieldPatch
    IssueCustomField.send(:include, RedmineSla::Patches::IssueCustomFieldPatch)
  end

  # Extend Issue with SLA computation methods
  unless Issue.included_modules.include? RedmineSla::Patches::IssuePatch
    Issue.send(:include, RedmineSla::Patches::IssuePatch)
  end

  # Extend IssueQuery and TimeEntryQuery for SLA filtering/sorting
  if (ActiveRecord::Base.connection.tables.include?('queries') rescue false)
    
    # SLA columns in issue queries
    unless IssueQuery.included_modules.include? RedmineSla::Patches::IssueQueryPatch
      IssueQuery.send(:include, RedmineSla::Patches::IssueQueryPatch)
    end

    # SLA columns in time entry queries
    unless TimeEntryQuery.included_modules.include? RedmineSla::Patches::TimeEntryQueryPatch
      TimeEntryQuery.send(:include, RedmineSla::Patches::TimeEntryQueryPatch)
    end
  end

end