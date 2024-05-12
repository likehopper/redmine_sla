desc <<-END_DESC
Build fixtures for plugin SLA

Available UPDATE SLA options:
  in     input CSV file ( default: plugins/redmine_sla/test/fixtures/config/fixtures.csv )
  out    output yml files dir results ( default: plugins/redmine_sla/test/fixtures/config/fixtures.yml )
  ff     output folder for fixture ( default: plugins/redmine_sla/test/fixtures/ )
  ff_red folder with redmine fixtures ( default: plugins/redmine_sla/files/src_redmine/ )
  ff_sla folder with sla fixtures ( default: plugins/redmine_sla/files/src_sla/ )

Example:
  rake --trace -f Rakefile --trace redmine:plugins:redmine_sla:build_fixture RAILS_ENV=development
END_DESC

namespace :redmine do

  namespace :plugins do

    namespace :redmine_sla do

      def get_easter(year,days)
        a = year % 19
        b = year / 100
        c = year % 100
        d = b / 4
        e = b % 4
        f = (b + 8) / 25
        g = (b - f + 1) / 3
        h = (19 * a + b - d - g + 15) % 30
        i = c / 4
        k = c % 4
        l = (32 + 2 * e + 2 * i - h - k) % 7
        m = (a + 11 * h + 22 * l) / 451
        month = (h + l - 7 * m + 114) / 31
        day = ((h + l - 7 * m + 114) % 31) + 1
      
        (Date.new(year, month,day)+days).strftime("%Y-%m-%d")
      end      

      desc 'Build fixtures for plugin SLA'
      task :build_fixture, [:tz, :in, :out, :ff, :ff_red, :ff_sla]  => :environment  do |t, args|

        taskname = "rake redmine:plugins:redmine_sla:build_fixture"

        Rails.logger.info "#{taskname} BEGIN"

        # fetch arguments (with defaults)
        args.with_defaults(:tz => Dir.pwd+"/plugins/redmine_sla/test/config/timezone.csv")
        args.with_defaults(:in => Dir.pwd+"/plugins/redmine_sla/test/config/fixtures.csv")
        args.with_defaults(:out => Dir.pwd+"/plugins/redmine_sla/test/config/fixtures.yml")
        args.with_defaults(:ff => Dir.pwd+"/plugins/redmine_sla/test/fixtures/")
        args.with_defaults(:ff_red => Dir.pwd+"/plugins/redmine_sla/test/files/src_redmine/")
        args.with_defaults(:ff_sla => Dir.pwd+"/plugins/redmine_sla/test/files/src_sla/")

        # explode in vars
        file_tz_csv, file_in_csv, file_out_yml, file_out_fixtures, src_redmine_yaml, src_sla_yaml = [ args.tz, args.in, args.out, args.ff, args.ff_red, args.ff_sla ]
        
        # log vars of arguments
        Rails.logger.info "#{taskname} :file_tz_csv #{file_tz_csv}"
        Rails.logger.info "#{taskname} :file_in_csv #{file_in_csv}"
        Rails.logger.info "#{taskname} :file_out_yml #{file_out_yml}"
        Rails.logger.info "#{taskname} :file_out_fixtures #{file_out_fixtures}"
        Rails.logger.info "#{taskname} :src_redmine_yaml #{src_redmine_yaml}"
        Rails.logger.info "#{taskname} :src_sla_yaml #{src_sla_yaml}"

        # perform vars check
        if ( ! File.exist?(file_tz_csv) )
          Rails.logger.info "#{taskname} file_tz_csv NOT FOUND [ #{file_tz_csv} ]"
          raise Exception.new("#{taskname} file_tz_csv NOT FOUND [ #{file_tz_csv} ]")
        end
        if ( ! File.exist?(file_in_csv) )
          Rails.logger.info "#{taskname} file_in_csv NOT FOUND [ #{file_in_csv} ]"
          raise Exception.new("#{taskname} file_in_csv NOT FOUND [ #{file_in_csv} ]")
        end
        if ( ! File.exist?(file_out_fixtures) )
          Rails.logger.info "#{taskname} file_out_fixtures NOT FOUND [ #{file_out_fixtures} ]"
          raise Exception.new("#{taskname} file_out_fixtures NOT FOUND [ #{file_out_fixtures} ]")
        end
        if ( ! File.exist?(src_redmine_yaml) )
          Rails.logger.info "#{taskname} src_redmine_yaml NOT FOUND [ #{src_redmine_yaml} ]"
          raise Exception.new("#{taskname} src_redmine_yaml NOT FOUND [ #{src_redmine_yaml} ]")
        end
        if ( ! File.exist?(src_sla_yaml) )
          Rails.logger.info "#{taskname} src_sla_yaml NOT FOUND [ #{src_sla_yaml} ]"
          raise Exception.new("#{taskname} src_sla_yaml NOT FOUND [ #{src_sla_yaml} ]")
        end

        # Fixtures results
        fixture_id = 0
        fixtures ||= {}

        # id for projects
        project_id = 0
        member_id = 0
        member_role_id = 0
        enabled_module_id = 0
        projects_trackers_id = 0
        # bounds for project's interval tree 
        project_lft = 1
        project_rgt = 2
        # arrays for projects' yaml files
        projects ||= {}
        members ||= {}
        member_roles ||= {}
        enabled_modules ||= {}
        projects_trackers ||= {}

        # id for issue
        issue_id = 0
        # arrays for issues' yaml files
        issues ||= {}
        journals ||= {}
        journal_details ||= {}
        custom_values ||= {}

        # For priorities & time entries !!!
        enumerations = {
          "Low"    => {"id" => 1, "name" => "Low",    "type" => "IssuePriority", "position" => 1, "position_name" => "lowest",  "active" => true, "is_default" => false },
          "Normal" => {"id" => 2, "name" => "Normal", "type" => "IssuePriority", "position" => 2, "position_name" => "default", "active" => true, "is_default" => true },
          "High"   => {"id" => 3, "name" => "High",   "type" => "IssuePriority", "position" => 3, "position_name" => "highest", "active" => true, "is_default" => false },
          "Development"   => {"id" => 4, "name" => "Development",   "type" => "TimeEntryActivity", "position" => 1, "position_name" => nil, "active" => true, "is_default" => true },
        }

        # For compatibility with sla custom fields !
        custom_field_enumerations = {
          "Minor" => { "id" => 1 },
          "Major" => { "id" => 2 },
          "Blocking" => { "id" => 3 },
        }

        # For statuses
        issue_statuses = {
          "New"      => { "id" => 1, "name" => "New",      "is_closed" => false, "position" => 1 },
          "Assigned" => { "id" => 2, "name" => "Assigned", "is_closed" => false, "position" => 2 },
          "Feedback" => { "id" => 3, "name" => "Feedback", "is_closed" => false, "position" => 3 },
          "Resolved" => { "id" => 4, "name" => "Resolved", "is_closed" => false, "position" => 4 },
          "Closed"   => { "id" => 5, "name" => "Closed",   "is_closed" => true,  "position" => 5 },
          "Rejected" => { "id" => 6, "name" => "Rejected", "is_closed" => true,  "position" => 6 },
        }

        # For trackers
        trackers = {
          "tracker_bug"                 => { "id" => 1, "name" => "tracker_bug",                 "default_status_id" => 1, "position" => 1, "description" => "Description for TMA HO tracker Bug ( HO with GTI/GTR )" },
          "tracker_feature_request"     => { "id" => 2, "name" => "tracker_feature_request",     "default_status_id" => 1, "position" => 2, "description" => "Description for TMA HO tracker Feature request ( NO SLA )" },
          "tracker_support_request"     => { "id" => 3, "name" => "tracker_support_request",     "default_status_id" => 1, "position" => 3, "description" => "Description for TMA HO tracker Support request ( HO with GTI only )" },
          "tracker_change_request"      => { "id" => 4, "name" => "tracker_change_request",      "default_status_id" => 1, "position" => 4, "description" => "Description for INFO HO tracker change request ( HO continued with GTI/GTR )" },
          "tracker_production_incident" => { "id" => 5, "name" => "tracker_production_incident", "default_status_id" => 1, "position" => 5, "description" => "Description for INFO HNO tracker production incident ( HNO continued with GTI/GTR )" },
          # "tracker_bug_cf"              => { "id" => 6, "name" => "tracker_bug_cf",              "default_status_id" => 1, "position" => 6, "description" => "Description for TMA HO tracker Bug ( HO with GTI/GTR ) with Custom Field" },
          # "tracker_feature_request_cf"  => { "id" => 7, "name" => "tracker_feature_request_cf",  "default_status_id" => 1, "position" => 7, "description" => "Description for TMA HO tracker Feature request ( NO SLA ) with Custom Field" },
        }

        # For workflows
        workflow_base = {
          "0to1"=> { "old_status_id" => 0, "new_status_id" => 1, "type" => "WorkflowTransition" },
          "0to2"=> { "old_status_id" => 0, "new_status_id" => 2, "type" => "WorkflowTransition" },
          "1to2"=> { "old_status_id" => 1, "new_status_id" => 2, "type" => "WorkflowTransition" },
          "1to3"=> { "old_status_id" => 1, "new_status_id" => 3, "type" => "WorkflowTransition" },
          "1to4"=> { "old_status_id" => 1, "new_status_id" => 4, "type" => "WorkflowTransition" },
          "1to5"=> { "old_status_id" => 1, "new_status_id" => 5, "type" => "WorkflowTransition" },
          "1to6"=> { "old_status_id" => 1, "new_status_id" => 6, "type" => "WorkflowTransition" },
          "2to3"=> { "old_status_id" => 2, "new_status_id" => 3, "type" => "WorkflowTransition" },
          "2to4"=> { "old_status_id" => 2, "new_status_id" => 4, "type" => "WorkflowTransition" },
          "2to5"=> { "old_status_id" => 2, "new_status_id" => 5, "type" => "WorkflowTransition" },
          "2to6"=> { "old_status_id" => 2, "new_status_id" => 6, "type" => "WorkflowTransition" },
          "3to2"=> { "old_status_id" => 3, "new_status_id" => 2, "type" => "WorkflowTransition" },
          "3to4"=> { "old_status_id" => 3, "new_status_id" => 4, "type" => "WorkflowTransition" },
          "3to5"=> { "old_status_id" => 3, "new_status_id" => 5, "type" => "WorkflowTransition" },
          "4to2"=> { "old_status_id" => 4, "new_status_id" => 2, "type" => "WorkflowTransition" },
          "4to3"=> { "old_status_id" => 4, "new_status_id" => 3, "type" => "WorkflowTransition" },
          "4to5"=> { "old_status_id" => 4, "new_status_id" => 5, "type" => "WorkflowTransition" },
        } 
        workflows = {}
        # Preapre workflows for roles admin(1), manager(2), developer(3), sysadmin(4), reporter(5) and other(6)
        for role_id in 1..6
          # Preapre workflows for roles
          trackers.each do |tracker|
            workflow_base.each do |workflow|
              workflows.store(workflow.first+"for#{role_id}with#{tracker[1]["id"]}",{ "role_id" => role_id, "tracker_id" => tracker[1]["id"] }.merge(workflow[1]))
            end
          end
        end

        # For sla_holidays
        sla_holidays = {}
        sla_holiday_id = 0
        for year in 2021..2024
          sla_holidays.store("#{(sla_holiday_id+=1)}", { "id" => sla_holiday_id, "date" => "#{year}-01-01",     "name" => "Jour de l'an" })
          sla_holidays.store("#{(sla_holiday_id+=1)}", { "id" => sla_holiday_id, "date" => get_easter(year,1),  "name" => "Lundi de Pâques" })
          sla_holidays.store("#{(sla_holiday_id+=1)}", { "id" => sla_holiday_id, "date" => "#{year}-05-01",     "name" => "Fête du travail" })
          sla_holidays.store("#{(sla_holiday_id+=1)}", { "id" => sla_holiday_id, "date" => "#{year}-05-08",     "name" => "Victoire 1945" })
          sla_holidays.store("#{(sla_holiday_id+=1)}", { "id" => sla_holiday_id, "date" => get_easter(year,39), "name" => "Ascension" })
          sla_holidays.store("#{(sla_holiday_id+=1)}", { "id" => sla_holiday_id, "date" => get_easter(year,50), "name" => "Pentecôte" })
          sla_holidays.store("#{(sla_holiday_id+=1)}", { "id" => sla_holiday_id, "date" => "#{year}-07-14",     "name" => "Fête nationale" })
          sla_holidays.store("#{(sla_holiday_id+=1)}", { "id" => sla_holiday_id, "date" => "#{year}-08-15",     "name" => "Assomption" })
          sla_holidays.store("#{(sla_holiday_id+=1)}", { "id" => sla_holiday_id, "date" => "#{year}-11-01",     "name" => "Toussaint" })
          sla_holidays.store("#{(sla_holiday_id+=1)}", { "id" => sla_holiday_id, "date" => "#{year}-11-11",     "name" =>  "Armistice" })
          sla_holidays.store("#{(sla_holiday_id+=1)}", { "id" => sla_holiday_id, "date" => "#{year}-12-25",     "name" => "Jour de Noël" })
        end

        # For sla_calendar_holidays
        sla_calendar_holidays = {}
        sla_calendar_holidays_id = 0
        for sla_calendar_id in 1..7
          sla_holidays.each do |sla_holiday|
            sla_calendar_holidays.store(
              "#{(sla_calendar_holidays_id+=1)}", { 
                "id" => sla_calendar_holidays_id,
                "sla_calendar_id" => sla_calendar_id,
                "sla_holiday_id" => sla_holiday[1]["id"],
                "match" => ( [4,7].include?(sla_calendar_id) ? true : false ),
              }
            )
          end
        end

        file_tz_csv_header = CSV.read(file_tz_csv).shift
        Setting.plugin_redmine_sla['sla_time_zone'] = file_tz_csv_header[0].to_s
        Setting.send "plugin_redmine_sla=", Setting.plugin_redmine_sla
        Rails.logger.info "#{taskname} file_tz_csv = [ #{Setting.plugin_redmine_sla} ]"

        sla_types ||= {}
        file_in_csv_header = CSV.read(file_in_csv).shift
        fields_sla_types = file_in_csv_header.select { |field| field.to_s.start_with?("sla_type") }

        file_in_csv_content = CSV.parse(File.read(file_in_csv), headers: true)
        file_in_csv_content.each_with_index do |row|

          # Auto create project if necessary
          Rails.logger.info "#{taskname} SEARCH project_id = #{row["project_name"]}]}"
          if ( projects[row["project_name"]].nil? )

            # Project creation
            project_id += 1
            project_identifier = row["project_name"]
            project_new = {
                "id" => project_id,
                "name" => project_identifier,
                "identifier" => project_identifier,
                "description" => "Automatic generation of a project",
                "created_on" => "2021-11-11 11:11:11 CET",
                "updated_on" => "2021-11-11 11:11:11 CET",
                "is_public" => false,
                "lft" => project_lft,
                "rgt" => project_rgt,
            }
            projects[project_identifier] = project_new
            project_lft += 2
            project_rgt += 2

            Rails.logger.info "#{taskname} ADD project = #{projects}"

            # members module activation for user manager
            member_id += 1
            member_identifier = project_identifier+"_members_"+member_id.to_s.rjust(4,"0")
            member_new = {
                "id" => member_id,
                "project_id" => project_id, 
                "user_id" => 2, # user manager
                "created_on" => "2021-11-11 11:11:11 CET",
                "mail_notification" => false,
            }
            members[member_identifier] = member_new
            # member_roles module activation for role manager
            member_role_id += 1
            member_role_identifier = project_identifier+"_members_role_"+member_id.to_s.rjust(4,"0")
            member_role_new = {
                "id" => member_role_id,
                "member_id" => member_id,
                "role_id" => 1, # role manager
            }
            member_roles[member_role_identifier] = member_role_new   

            # members module activation for role « resolver » ( user developer & sysadmin )
            member_id += 1
            member_identifier = project_identifier+"_members_"+member_id.to_s.rjust(4,"0")
            member_new = {
                "id" => member_id,
                "project_id" => project_id, 
                "user_id" => row["resolver"], #  role resolver = user developer & sysadmin
                "created_on" => "2021-11-11 11:11:11 CET",
                "mail_notification" => false,
            }
            members[member_identifier] = member_new       
            # member_roles module activation for role developer
            member_role_id += 1
            member_role_identifier = project_identifier+"_members_role_"+member_id.to_s.rjust(4,"0")
            member_role_new = {
                "id" => member_role_id,
                "member_id" => member_id,
                "role_id" => 2, # role resolver
            }
            member_roles[member_role_identifier] = member_role_new  

            # members module activation for user reporter
            member_id += 1
            member_identifier = project_identifier+"_members_"+member_id.to_s.rjust(4,"0")
            member_new = {
                "id" => member_id,
                "project_id" => project_id, 
                "user_id" => 5, # user reporter
                "created_on" => "2021-11-11 11:11:11 CET",
                "mail_notification" => false,
            }
            members[member_identifier] = member_new          
            # member_roles module activation for role reporter              
            member_role_id += 1
            member_role_identifier = project_identifier+"_members_role_"+member_id.to_s.rjust(4,"0")
            member_role_new = {
                "id" => member_role_id,
                "member_id" => member_id,
                "role_id" => 3, # role reporter
            }
            member_roles[member_role_identifier] = member_role_new          

            # issue_tracking module activation for tests
            enabled_module_id += 1
            enabled_module_identifier = "enabled_module_"+enabled_module_id.to_s.rjust(4,"0")
            enabled_module_new = {
                "project_id" => project_id, 
                "name" => "issue_tracking",
            }
            enabled_modules[enabled_module_identifier] = enabled_module_new
            # time_entry module activation for tests
            enabled_module_id += 1
            enabled_module_identifier = "enabled_module_"+enabled_module_id.to_s.rjust(4,"0")
            enabled_module_new = {
                "project_id" => project_id, 
                "name" => "time_tracking",
            }
            enabled_modules[enabled_module_identifier] = enabled_module_new
            # sla module activation for tests
            enabled_module_id += 1
            enabled_module_identifier = "enabled_module_"+enabled_module_id.to_s.rjust(4,"0")
            enabled_module_new = {
                "project_id" => project_id, 
                "name" => "sla",
            }
            enabled_modules[enabled_module_identifier] = enabled_module_new

            # Activation of all trackers for testing
            trackers.each do |tracker| 
              projects_trackers_id += 1
              projects_trackers_identifier = "projects_trackers_"+projects_trackers_id.to_s.rjust(4,"0")
              projects_trackers_new = {
                  "project_id" => project_id, 
                  "tracker_id" => tracker[1]["id"],
              }              
              projects_trackers[projects_trackers_identifier] =  projects_trackers_new

            end

          end

          Rails.logger.info "#{taskname} FOUND project_id = #{project_id}" 

          # Search for tracker
          if ( trackers[row["tracker_name"]].nil? )
            Rails.logger.info "#{taskname} NOT FOUND tracker_name [ #{row["tracker_name"]} ]"
            raise Exception.new("#{taskname} NOT FOUND tracker_name [ #{row["tracker_name"]} ]")
          end
          Rails.logger.info "#{taskname} FOUND tracker_name [ #{row["tracker_name"]} ]"
          tracker_id = trackers[row["tracker_name"]]["id"]
          Rails.logger.info "#{taskname} FOUND tracker_id = #{tracker_id}"

          # Default status_id is closed (1)
          status_id = issue_statuses["Closed"]["id"]
          Rails.logger.info "#{taskname} FOUND status_id = #{status_id} ( Closed )"

          issue_id += 1
          
          issue_identifier = "issue_"+issue_id.to_s.rjust(4,"0")

          issue_new = {
              "id" => issue_id,
              "subject" => row["issue_subject"],
              "description" => row["issue_description"],
              "project_id" => project_id,
              "tracker_id" => tracker_id,
              "assigned_to_id" => row["resolver"], # role resolver = user developer & sysadmin
              "author_id" => 5, # user reporter
              "status_id" => status_id,
              "priority_id" => ( row["custom_field_name"].empty? ? enumerations[row["issue_priority"]]["id"] : enumerations["Normal"]["id"] ) ,
              "created_on" => row["issue_date_created"],
              "updated_on" => row["issue_date_closed"],
              "closed_on" => row["issue_date_closed"],
              "start_date" => row["issue_date_created"],
              "due_date" => row["issue_date_closed"],
              "estimated_hours" => 0.5,
              "done_ratio" => 100,
              "root_id" => 2,
              "lft" => 1,
              "rgt" => 2,
          }          
          
          
          issues[issue_identifier] = issue_new

          custom_values.store( custom_values.size+1, { "id" => custom_values.size+1,
            "customized_type"   => "Issue",
            "customized_id"	    => issue_id,
            "custom_field_id"   => 1,
            "value"             =>  custom_field_enumerations[row["issue_priority"]]["id"]
          } ) if ! row["custom_field_name"].empty?

          journal_id_1 = ( ( issue_id - 1 ) * 3 ) + 1
          journal_id_2 = journal_id_1 + 1
          journal_id_3 = journal_id_2 + 1
          journal_identifier_1 = issue_identifier+"_journal_"+journal_id_1.to_s.rjust(4,"0")
          journal_identifier_2 = issue_identifier+"_journal_"+journal_id_2.to_s.rjust(4,"0")
          journal_identifier_3 = issue_identifier+"_journal_"+journal_id_3.to_s.rjust(4,"0")

          journal_new = {
            "id" => journal_id_1,
            "user_id" => 5, # user reporter
            "journalized_id" => issue_id,
            "journalized_type" => "Issue",
            "created_on" => row["issue_date_assigned"],
            "notes" => "Issue Assigned to close GTI",
          }
          journals[journal_identifier_1] = journal_new
          journal_new = {
            "id" => journal_id_2,
            "user_id" => row["resolver"], # role resolver = user developer & sysadmin
            "journalized_id" => issue_id,
            "journalized_type" => "Issue",
            "created_on" => row["issue_date_resolved"],
            "notes" => "Issue Resolved to close GTR",
          }
          journals[journal_identifier_2] = journal_new
          journal_new = {
            "id" => journal_id_3,
            "user_id" => 2, # user manager
            "journalized_id" => issue_id,
            "journalized_type" => "Issue",
            "created_on" => row["issue_date_closed"],
            "notes" => "Issue Closed",
          }
          journals[journal_identifier_3] = journal_new

          journal_detail_id_1 = ( ( issue_id - 1 ) * 6 ) + 1
          journal_detail_id_2 = journal_detail_id_1 + 1 
          journal_detail_id_3 = journal_detail_id_2 + 1 
          journal_detail_id_4 = journal_detail_id_3 + 1 
          journal_detail_id_5 = journal_detail_id_4 + 1 
          journal_detail_id_6 = journal_detail_id_5 + 1 
          journal_detail_identifier_1 = journal_identifier_1+"_journal_detail_"+journal_detail_id_1.to_s.rjust(4,"0")
          journal_detail_identifier_2 = journal_identifier_1+"_journal_detail_"+journal_detail_id_2.to_s.rjust(4,"0")
          journal_detail_identifier_3 = journal_identifier_2+"_journal_detail_"+journal_detail_id_3.to_s.rjust(4,"0")
          journal_detail_identifier_4 = journal_identifier_2+"_journal_detail_"+journal_detail_id_4.to_s.rjust(4,"0")
          journal_detail_identifier_5 = journal_identifier_3+"_journal_detail_"+journal_detail_id_5.to_s.rjust(4,"0")
          journal_detail_identifier_6 = journal_identifier_3+"_journal_detail_"+journal_detail_id_6.to_s.rjust(4,"0")

          journal_detail_new = {
            "id" => journal_detail_id_1,
            "journal_id" => journal_id_1,
            "property" => "attr",
            "prop_key" => "done_ratio",
            "old_value" => "0",
            "value" => "40",
          }
          journal_details[journal_detail_identifier_1] = journal_detail_new
          journal_detail_new = {
            "id" => journal_detail_id_2,
            "journal_id" => journal_id_1,
            "property" => "attr",
            "prop_key" => "status_id",
            "old_value" => issue_statuses["New"]["id"],
            "value" => issue_statuses["Assigned"]["id"],
          }
          journal_details[journal_detail_identifier_2] = journal_detail_new
          journal_detail_new = {
            "id" => journal_detail_id_3,
            "journal_id" => journal_id_2,
            "property" => "attr",
            "prop_key" => "done_ratio",
            "old_value" => "40",
            "value" => "80",
          }
          journal_details[journal_detail_identifier_3] = journal_detail_new
          journal_detail_new = {
            "id" => journal_detail_id_4,
            "journal_id" => journal_id_2,
            "property" => "attr",
            "prop_key" => "status_id",
            "old_value" => issue_statuses["Assigned"]["id"],
            "value" => issue_statuses["Resolved"]["id"],
          }
          journal_details[journal_detail_identifier_4] = journal_detail_new
          journal_detail_new = {
            "id" => journal_detail_id_5,
            "journal_id" => journal_id_3,
            "property" => "attr",
            "prop_key" => "done_ratio",
            "old_value" => "80",
            "value" => "100",
          }
          journal_details[journal_detail_identifier_5] = journal_detail_new
          journal_detail_new = {
            "id" => journal_detail_id_6,
            "journal_id" => journal_id_3,
            "property" => "attr",
            "prop_key" => "status_id",
            "old_value" => issue_statuses["Resolved"]["id"],
            "value" => issue_statuses["Closed"]["id"],
          }
          journal_details[journal_detail_identifier_6] = journal_detail_new

          # Add fixture 
          fixture_id += 1
          fixture_identifier ="fixture_"+fixture_id.to_s.rjust(4,"0")
          fixture_new = {
            "issue_id" => issue_id,
            "sla_types" => {},
          }
          fields_sla_types.each do |field|
            sla_type_id = field.split("_")[2].to_i
            sla_type_action = field.split("_")[3].to_s
            if ( ! ["term","spent"].include?(sla_type_action) )
              raise Exception.new("#{taskname} ERROR header field type_id_term | type_id_term")
            end
            if ( !row[field].nil? && row[field].to_i > 0 )
              if ( fixture_new["sla_types"][sla_type_id.to_s].nil? )
                fixture_new["sla_types"][sla_type_id.to_s] ||= {}
              end
              fixture_new["sla_types"][sla_type_id.to_s][sla_type_action] = row[field].to_i
            end
          end # fields_types.each do |field|
          fixtures[fixture_identifier] = fixture_new

        end

        File.write( file_out_yml, fixtures.to_yaml )

        # Write issues files in yaml with array issues
        File.write( file_out_fixtures+"/issues.yml", issues.to_yaml )
        # Write journals files in yaml with array journals
        File.write( file_out_fixtures+"/journals.yml", journals.to_yaml )
        # Write journal_details files in yaml with array journal_details
        File.write( file_out_fixtures+"/journal_details.yml", journal_details.to_yaml )
        # Write custom_values files in yaml with array custom_values
        File.write( file_out_fixtures+"/custom_values.yml", custom_values.to_yaml )

        # Write enumerations files in yaml with array enumerations
        File.write( file_out_fixtures+"/enumerations.yml", enumerations.to_yaml )
        # Write issue_statuses files in yaml with array issue_statuses
        File.write( file_out_fixtures+"/issue_statuses.yml", issue_statuses.to_yaml )
        # Write trackers files in yaml with array trackers
        File.write( file_out_fixtures+"/trackers.yml", trackers.to_yaml )
        # Write workflows files in yaml with array workflows
        File.write( file_out_fixtures+"/workflows.yml", workflows.to_yaml )

        # Write sla_holidays files in yaml with array sla_holidays
        File.write( file_out_fixtures+"/sla_holidays.yml", sla_holidays.to_yaml )
        # Write sla_calendar_holidays files in yaml with array sla_calendar_holidays
        File.write( file_out_fixtures+"/sla_calendar_holidays.yml", sla_calendar_holidays.to_yaml )
        
        File.write( file_out_fixtures+"/projects.yml", projects.to_yaml )
        File.write( file_out_fixtures+"/members.yml", members.to_yaml )
        File.write( file_out_fixtures+"/member_roles.yml", member_roles.to_yaml )
        File.write( file_out_fixtures+"/enabled_modules.yml", enabled_modules.to_yaml )
        File.write( file_out_fixtures+"/projects_trackers.yml", projects_trackers.to_yaml )
        
        FileUtils.copy Dir["#{src_redmine_yaml}/*.yml"], file_out_fixtures
        FileUtils.copy Dir["#{src_sla_yaml}/*.yml"], file_out_fixtures

        
        # End
        Rails.logger.info "#{taskname} END"

      end # task :build_fixture => :environment do

    def init_task
      unless ENV['DRY_RUN'].nil?
      trace "\n!!! Dry-run execution !!!\n"
      end
    end # def init_task

    def trace(msg)
      puts msg
    end # def trace(msg)

    end # namespace :redmine_sla do

  end # namespace :plugins do

end # namespace :redmine do