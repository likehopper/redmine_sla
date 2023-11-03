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

require_dependency 'time_entry_query'

module RedmineSla
  
  module Patches

    # Patches Redmine's QueryController dynamically
    module TimeEntryQueryPatch
      
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
            unloadable
            alias_method :available_filters_without_sla, :available_filters
            alias_method :available_filters, :available_filters_with_sla
    
              sla_get_level = QueryColumn.new(
                  :sla_get_level,
                  :caption => Proc.new { l(:sla_label_abbreviation)+" "+l("sla_label.sla_level.singular") },
                  :groupable => true,
                  :sortable => "(SELECT sla_levels.name FROM sla_caches INNER JOIN sla_levels ON ( sla_caches.sla_level_id = sla_levels.id ) WHERE sla_caches.issue_id = issues.id ORDER BY sla_levels.name)",
                )
                
                def sla_get_level.group_by_statement
                  "(SELECT sla_levels.name FROM sla_caches INNER JOIN sla_levels ON ( sla_caches.sla_level_id = sla_levels.id ) WHERE sla_caches.issue_id = issues.id ORDER BY sla_levels.name)"
                end
                self.available_columns << sla_get_level


                if ActiveRecord::Base.connection.table_exists? 'sla_types'
                  SlaType.all.each { |sla_type|
                    name = "sla_get_respect_#{sla_type.id}"

                    sla_get_respect = QueryColumn.new(
                      name.to_sym,
                      :caption => Proc.new { l(:sla_label_abbreviation)+" "+l(:label_sla_respect)+" "+sla_type.name },
                      :groupable => true,
                      :sortable => "(
                        SELECT distinct CASE
                          WHEN sla_cache_spents.spent IS NULL THEN 0
                          WHEN (sla_level_terms.term-sla_cache_spents.spent)>0 THEN 1
                          ELSE 2 END AS sla_respect
                        FROM time_entries sub_time_entries						
                        INNER join issues AS sub_issues ON sub_time_entries.issue_id=sub_issues.id
                        LEFT JOIN sla_caches ON ( sub_issues.id = sla_caches.issue_id )
                        LEFT JOIN sla_cache_spents ON ( sla_caches.id = sla_cache_spents.sla_cache_id AND sla_cache_spents.sla_type_id = #{sla_type.id} )
                        LEFT JOIN sla_levels ON ( sla_caches.sla_level_id = sla_levels.id )
                        LEFT JOIN sla_level_terms ON ( sla_levels.id = sla_level_terms.sla_level_id AND sla_level_terms.sla_type_id = #{sla_type.id} )
                        WHERE sub_time_entries.id = time_entries.id
                        ORDER BY sla_respect
                      )",
                    )
                    def sla_get_respect.group_by_statement
                      self.sortable
                    end
                    self.available_columns << sla_get_respect
                  }
                end
                
        end

      end

    end


    module InstanceMethods

      def available_filters_with_sla

        if @available_filters.blank?

          values ||= []
          SlaLevel.pluck(:name,:id).map { |name,id|
              values << [name.to_s,id.to_s]
          }

          add_available_filter('sla_level_id',
                              :type => :list,
                              :name => l(:sla_label_abbreviation)+" "+l("sla_label.sla_level.singular"),
                              :values => values
          ) unless available_filters_without_sla.key?('sla_level_id') && !User.current.allowed_to?(:view_sla, project, :global => true)

          SlaType.all.each { |sla_type|
            add_available_filter("sla_respect_#{sla_type.id}",
                                :type => :list,
                                :name => l(:sla_label_abbreviation)+" "+l(:label_sla_respect)+" "+sla_type.name,
                                :values => [[l(:general_text_Yes), '1'], [l(:general_text_No), '0']]
            ) unless available_filters_without_sla.key?("sla_respect_#{sla_type.id}") && !User.current.allowed_to?(:view_sla, project, :global => true)              
          }

        else
          available_filters_without_sla
        end

        @available_filters

      end

      if ActiveRecord::Base.connection.table_exists? 'sla_types'
        SlaType.all.each { |sla_type|
          define_method("sql_for_sla_respect_#{sla_type.id}_field") do |field, operator, value|
            sql_for_sla_respect_field(field,operator,value,sla_type.id)
          end
        }    
      end

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

#unless TimeEntryQuery.included_modules.include? RedmineSla::Patches::TimeEntryQueryPatch
#  TimeEntryQuery.included_modules.exclude?(RedmineSla::Patches::TimeEntryQueryPatch)
#  TimeEntryQuery.send(:include, RedmineSla::Patches::TimeEntryQueryPatch)
#end