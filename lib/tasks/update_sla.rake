desc <<-END_DESC
Update SLA ( ie. GTI and GTR )

Available UPDATE SLA options:
  scope=[all,miss,inprogress]         Scope to upate issues (Default: inprogress)

Example:
  rake --trace -f Rakefile --trace redmine:plugins:redmine_sla:update_sla RAILS_ENV=production
END_DESC

namespace :redmine do
  namespace :plugins do
    namespace :redmine_sla do
      task :update_sla => :environment do

        update_sla_options = {:scope => ENV['scope'] }

        scope = update_sla_options[:scope] || 'inprogress'

        case scope
        when "inprogress"
          Rails.logger.info "rake redmine:plugins:redmine_sla:update START whith SCOPE 'inprogress' (default)"
        #when "miss"
        #    Rails.logger.info "rake redmine:plugins:redmine_sla:update START with SCOPE 'miss'" 
        when "all"
          Rails.logger.info "rake redmine:plugins:redmine_sla:update START with SCOPE 'all'" 
        else
          Rails.logger.info "rake redmine:plugins:redmine_sla:update SCOPE ERROR" 
            abort( "SCOPE ERROR" ) 
        end

        settings = Setting.plugin_redmine_sla
        Rails.logger.info "rake redmine:plugins:redmine_sla:update settings #{settings}"

        # AW : TODO : filtrer sur projet actifs avec module activé
        Project.has_module(:sla).each do |project|

          puts "##{project.id} - #{project.name}"

          # IF project close THEN pass
          if ( project.status != 1 ) then
            # Clear Cache
            SlaCache.where(issue_id: project.issues.map(&:id)).destroy_all
            Rails.logger.info "rake redmine:plugins:redmine_sla:update Project n°#{project.id} [#{project.identifier}] CLEAR CACHE & PASS PROJECT CLOSE..."
            next
          end

          # IF project without sla THEN pass
          if ( ! project.module_enabled?(:sla) ) then
            # Clear cache
            # SlaCache.where(issue_id: project.issues.map(&:id)).destroy_all
            SlaCache.where(project_id: project.id).destroy_all
            #Rails.logger.info "rake redmine:plugins:redmine_sla:update Project n°#{project.id.to_s} [#{project.identifier}] CLEAR CACHE & PASS PROJECT WITHOUT SLA..."
            next
          end

          Rails.logger.info "rake redmine:plugins:redmine_sla:update Project ##{project.id.to_s} = #{project.identifier} "
           
          project.issues.where(tracker_id: SlaProjectTracker.where(project_id: project.id).map(&:tracker_id)).each do |issue|

            puts "\t##{issue.id} - #{issue.subject}"

            SlaType.all.each { |sla_type|
              issue.get_sla_spent(sla_type.id)
            }
              
            # Rails.logger.info "rake redmine:plugins:redmine_sla:update Issue n°#{issue.id.to_s} [ tracker_id = #{issue.tracker_id.to_s} ] [ status_id = #{issue.status_id.to_s} ] TODO #{issue.subject}  "
            # SlaCacheSpent.update_by_issue_id(issue.id)
            # Rails.logger.info "rake redmine:plugins:redmine_sla:update Issue n°#{issue.id.to_s} CACHE UPDATE"

          end

        end

        Rails.logger.info "rake redmine:plugins:redmine_sla:update END"

    end

    def init_task
      unless ENV['DRY_RUN'].nil?
      trace "\n!!! Dry-run execution !!!\n"
      end
    end

    def trace(msg)
      puts msg
    end

    end 
  end 
end