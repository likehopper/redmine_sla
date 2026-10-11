# File: redmine_sla/lib/tasks/update_sla.rake
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Redmine SLA - service level agreement plugin
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
desc <<-END_DESC
Update SLA ( ie. GTI and GTR )

Available UPDATE SLA options:
  scope=[all,miss,inprogress]         Scope to update issues (Default: inprogress)
                                      inprogress: open issues, and closed issues
                                      not updated since their closing
                                      miss: issues without SLA cache
                                      all: all issues
  projects=[all,with_sla,without_sla] Projects to process (Default: all)
                                      with_sla: update the SLA cache of projects
                                      with the SLA module enabled
                                      without_sla: only purge the SLA cache left
                                      on projects with the SLA module disabled
                                      Projects not active (closed, archived)
                                      are passed: their SLA cache is kept as is

Example:
  rake --trace -f Rakefile --trace redmine:plugins:redmine_sla:update_sla RAILS_ENV=production
  rake redmine:plugins:redmine_sla:update_sla projects=without_sla RAILS_ENV=production
END_DESC

namespace :sla do
  task :update => :environment do

    update_sla_options = { scope: ENV['scope'], projects: ENV['projects'] }

    scope = update_sla_options[:scope] || 'inprogress'
    projects_option = update_sla_options[:projects] || 'all'

    Rails.logger.info "rake redmine:plugins:redmine_sla:update STARTEND -> scope: #{scope}"

    case scope
    when "inprogress"
      Rails.logger.info "rake redmine:plugins:redmine_sla:update START whith SCOPE 'inprogress' (default)"
    when "miss"
      Rails.logger.info "rake redmine:plugins:redmine_sla:update START with SCOPE 'miss'"
    when "all"
      Rails.logger.info "rake redmine:plugins:redmine_sla:update START with SCOPE 'all'" 
    else
      Rails.logger.info "rake redmine:plugins:redmine_sla:update SCOPE ERROR" 
        abort( "SCOPE ERROR" ) 
    end

    sla_project_ids = EnabledModule.where(name: 'sla').select(:project_id)
    projects =
      case projects_option
      when "all" then Project.all
      when "with_sla" then Project.where(id: sla_project_ids)
      when "without_sla" then Project.where.not(id: sla_project_ids)
      else
        Rails.logger.info "rake redmine:plugins:redmine_sla:update PROJECTS ERROR"
        abort( "PROJECTS ERROR" )
      end
    Rails.logger.info "rake redmine:plugins:redmine_sla:update PROJECTS '#{projects_option}'"

    settings = Setting.plugin_redmine_sla
    Rails.logger.info "rake redmine:plugins:redmine_sla:update settings #{settings}"

    projects.order(:id).each do |project|

      puts "##{project.id} - #{project.name}"

      # IF project without sla THEN clear the cache left behind and pass
      # (its SLA configuration is kept for re-enabling the module)
      if ( ! project.module_enabled?(:sla) ) then
        SlaCache.purge(project)
        Rails.logger.info "rake redmine:plugins:redmine_sla:update Project n°#{project.id} [#{project.identifier}] CLEAR CACHE & PASS PROJECT WITHOUT SLA MODULE..."
        next
      end

      # IF project not active (closed, archived...) THEN pass
      # (its SLA cache is kept as it was, nothing is updated)
      if ( project.status != Project::STATUS_ACTIVE ) then
        Rails.logger.info "rake redmine:plugins:redmine_sla:update Project n°#{project.id} [#{project.identifier}] KEEP CACHE & PASS PROJECT NOT ACTIVE..."
        next
      end

      Rails.logger.info "rake redmine:plugins:redmine_sla:update Project ##{project.id.to_s} = #{project.identifier} "
        
      issues = project.issues.where(tracker_id: SlaProjectTracker.where(project_id: project.id).map(&:tracker_id))

      case scope
      when "inprogress"
        # A closed issue is final once its spent time was updated after its
        # closing: sla_get_spent counts up to closed_on (both in SLA time zone).
        issues = issues.joins(:status).where(<<~SQL, false)
          issue_statuses.is_closed = ?
          OR NOT EXISTS (
            SELECT 1 FROM sla_cache_spents
            WHERE sla_cache_spents.issue_id = issues.id
            AND sla_cache_spents.updated_on > sla_get_date(issues.closed_on)
          )
        SQL
      when "miss"
        issues = issues.where("NOT EXISTS (SELECT 1 FROM sla_caches WHERE sla_caches.issue_id = issues.id)")
      end

      issues.order(:id).each do |issue|

        puts "\t##{issue.id} - #{issue.subject}"

        SlaType.all.each { |sla_type|
          issue.get_sla_spent(sla_type.id)
        }
          
      end

    end

    Rails.logger.info "rake redmine:plugins:redmine_sla:update END"

  end

end

namespace :redmine do
  namespace :plugins do
    namespace :redmine_sla do
      task :update_sla => 'sla:update'
    end
  end
end
