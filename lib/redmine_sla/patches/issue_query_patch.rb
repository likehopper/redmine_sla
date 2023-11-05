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

require_dependency 'issue_query'

module RedmineSla
  
  module Patches

    # Patches Redmine's QueryController dynamically
    module IssueQueryPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          alias_method :available_filters_without_sla, :available_filters
          alias_method :available_filters, :available_filters_with_sla

          def sql_for_sla_respect_field(field,operator,value,sla_type_id)
            condition =
              if value.size > 1
                '1=1'
              else
                is_done_val = value.join == '1' ? self.class.connection.quoted_true : self.class.connection.quoted_false
                case operator
                when '='
                  "( ( ( sla_level_terms.term - sla_cache_spents.spent ) > 0 ) = #{is_done_val} AND sla_level_terms.term IS NOT NULL )"
                when '!'
                  "( ( ( sla_level_terms.term - sla_cache_spents.spent ) > 0 ) != #{is_done_val} OR sla_level_terms.term IS NULL )"
                end
              end
            issue_ids = "
              SELECT DISTINCT issues.id
              FROM issues
              LEFT JOIN sla_caches ON ( issues.id = sla_caches.issue_id )
              LEFT JOIN sla_cache_spents ON ( sla_caches.id = sla_cache_spents.sla_cache_id AND sla_cache_spents.sla_type_id = #{sla_type_id} )
              LEFT JOIN sla_levels ON ( sla_caches.sla_level_id = sla_levels.id )
              LEFT JOIN sla_level_terms ON ( sla_levels.id = sla_level_terms.sla_level_id AND sla_level_terms.sla_type_id = #{sla_type_id} )
              WHERE #{condition} "
            "(#{Issue.table_name}.id IN (#{issue_ids}))"
          end
    
          def sql_for_sla_level_id_field(field, operator, value)
            neg = (operator == '!' ? 'NOT' : '')
            condition = "( sla_caches.sla_level_id #{neg} IN (#{value.join(',')}) AND sla_level_terms.term IS NOT NULL"
            issue_ids = "
              SELECT DISTINCT issues.id
              FROM issues
              LEFT JOIN sla_caches ON ( issues.id = sla_caches.issue_id )
              LEFT JOIN sla_cache_spents ON ( sla_caches.id = sla_cache_spents.sla_cache_id )
              LEFT JOIN sla_levels ON ( sla_caches.sla_level_id = sla_levels.id )
              LEFT JOIN sla_level_terms ON ( sla_levels.id = sla_level_terms.sla_level_id )
              WHERE #{condition} "
            "(#{Issue.table_name}.id IN (#{issue_ids}) ))"
          end
    
        end

      end

    end

    module InstanceMethods

      def available_filters_with_sla

        if @available_filters.blank?

          # SLA LEVEL : Filter
          # Equivalent query without "has_many...through"
          # for select only active sla_levels for this project :
          #     SELECT DISTINCT sla_levels.id, sla_levels.name
          #     FROM sla_project_trackers
          #     INNER JOIN slas ON ( slas.id = sla_project_trackers.sla_id )
          #     INNER JOIN sla_levels ON ( sla_levels.sla_id = slas.id )
          #     WHERE sla_project_trackers.project_id = #{project.id}
          values = SlaLevel.joins(:sla_project_trackers).where("sla_project_trackers.project_id = ?", project.id).select("sla_levels.id, sla_levels.name").distinct.pluck(:name,:id)
          add_available_filter('sla_level_id',
                              :type => :list,
                              :name => l(:sla_label_abbreviation)+" "+l("sla_label.sla_level.singular"),
                              :values => values
          ) unless available_filters_without_sla.key?('sla_level_id') && !User.current.allowed_to?(:view_sla, project, :global => true)

          # SLA LEVEL : Column
          sla_get_level = QueryColumn.new(
            :sla_get_level,
            :caption => Proc.new { l(:sla_label_abbreviation)+" "+l("sla_label.sla_level.singular") },
            :groupable => true,
            :sortable => "(SELECT sla_levels.name FROM sla_caches INNER JOIN sla_levels ON ( sla_caches.sla_level_id = sla_levels.id ) WHERE sla_caches.issue_id = issues.id ORDER BY sla_levels.name)",
          )
          def sla_get_level.group_by_statement
            self.sortable
          end
          self.available_columns << sla_get_level
          
          if ActiveRecord::Base.connection.table_exists? 'sla_types'

            # Equivalent query without "has_many...through"
            # for select only active sla_types for this project :
            #     SELECT DISTINCT sla_types.id, sla_types.name
            #     FROM sla_project_trackers
            #     INNER JOIN slas ON ( slas.id = sla_project_trackers.sla_id )
            #     INNER JOIN sla_levels ON ( sla_levels.sla_id = slas.id )
            #     INNER JOIN sla_level_terms ON ( sla_level_terms.sla_level_id = sla_levels.id )
            #     INNER JOIN sla_types ON ( sla_types.id = sla_level_terms.sla_type_id )
            #     WHERE sla_project_trackers.project_id = #{project.id}

            SlaType.joins(:sla_project_trackers).where("sla_project_trackers.project_id = ?", project.id).select("sla_types.id, sla_types.name").distinct.each { |sla_type|

              # SLA RESPECT : Filter
              add_available_filter("sla_respect_#{sla_type.id}",
                :type => :list,
                :name => l(:sla_label_abbreviation)+" "+l(:label_sla_respect)+" "+sla_type.name,
                :values => [[l(:general_text_Yes), '1'], [l(:general_text_No), '0']]
              ) unless available_filters_without_sla.key?("sla_respect_#{sla_type.id}") && !User.current.allowed_to?(:view_sla, project, :global => true)              
    
              # SLA RESPECT : Column
              name_to_sym = "sla_get_respect_#{sla_type.id}".to_sym
              self.available_columns.delete_if {|x| x.name == name }
              sla_get_respect = QueryColumn.new(
                name_to_sym,
                :caption => Proc.new { l(:sla_label_abbreviation)+" "+l(:label_sla_respect)+" "+sla_type.name },
                :groupable => true,
                :sortable => "(
                  SELECT DISTINCT CASE
                    WHEN sla_cache_spents.spent IS NULL THEN 0
                    WHEN (sla_level_terms.term-sla_cache_spents.spent)>0 THEN 1
                    ELSE 2 END AS sla_respect
                  FROM issues AS sub_issues
                  LEFT JOIN sla_caches ON ( sub_issues.id = sla_caches.issue_id )
                  LEFT JOIN sla_cache_spents ON ( sla_caches.id = sla_cache_spents.sla_cache_id AND sla_cache_spents.sla_type_id = #{sla_type.id} )
                  LEFT JOIN sla_levels ON ( sla_caches.sla_level_id = sla_levels.id )
                  LEFT JOIN sla_level_terms ON ( sla_levels.id = sla_level_terms.sla_level_id AND sla_level_terms.sla_type_id = #{sla_type.id} )
                  WHERE sub_issues.id = issues.id
                  ORDER BY sla_respect
                )",
              )
              def sla_get_respect.group_by_statement
                self.sortable
              end
              self.available_columns << sla_get_respect

              if ! singleton_methods.include? "sql_for_sla_respect_#{sla_type.id}_field".to_sym
                define_singleton_method("sql_for_sla_respect_#{sla_type.id}_field") do |field, operator, value|
                  sql_for_sla_respect_field(field,operator,value,sla_type.id)
                end
              end

            }

          end

        else
          available_filters_without_sla
        end

        @available_filters

      end

    end

  end

end

#unless IssueQuery.included_modules.include? RedmineSla::Patches::IssueQueryPatch
#  IssueQuery.included_modules.exclude?(RedmineSla::Patches::IssueQueryPatch)
#  IssueQuery.send(:include, RedmineSla::Patches::IssueQueryPatch)
#end
