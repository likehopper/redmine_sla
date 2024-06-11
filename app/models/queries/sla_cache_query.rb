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

class Queries::SlaCacheQuery < Query

  unloadable
  
  self.queried_class = SlaCache
  self.view_permission = :view_sla
  
  def initialize_available_filters
    add_available_filter 'project_id', type: :list, :name => :project, values: lambda {project_values} if project.nil?
    add_available_filter 'issue_id', type: :tree
    add_available_filter 'sla_level_id', :type => :list, :values => lambda {all_sla_level_values}
    add_available_filter 'start_date', type: :date_past
    add_available_filter 'created_on', :type => :date_past if User.current.admin?
    add_available_filter 'updated_on', :type => :date_past
    add_available_filter "issue.tracker_id", :type => :list_with_history, :name => l("label_attribute_of_issue",:name => l(:field_tracker)), :values => lambda {trackers.map {|t| [t.name, t.id.to_s]}}
    add_available_filter "issue.status_id", :type => :list_status, :name => l("label_attribute_of_issue", :name => l(:field_status)), :values => lambda {issue_statuses_values}

    if ! project.nil?
      SlaType.joins(:sla_project_trackers).where("sla_project_trackers.project_id = ?", project.id).select("sla_types.id, sla_types.name").distinct.each { |sla_type|
        # SLA Term : Filter ?
        # SLA Spent : Filter ?
        # SLA Remain : Filter
        add_available_filter("slas.sla_remain_#{sla_type.id}",
          :name => l(:label_sla_remain)+" "+sla_type.name,
          :type => :integer        )
        # SLA Remain : Filter Function
        if ! singleton_methods.include? "sql_for_slas_sla_remain_#{sla_type.id}_field".to_sym
          define_singleton_method("sql_for_slas_sla_remain_#{sla_type.id}_field") do |field, operator, value|
            sql_for_slas_sla_remain_field(field,operator,value,sla_type.id)
          end
        end
        # SLA Respect : Filter
        add_available_filter("slas.sla_respect_#{sla_type.id}",
          :name => l(:label_sla_respect)+" "+sla_type.name,
          :type => :list,
          :values => [[l(:general_text_Yes), '1'], [l(:general_text_No), '0']]
        )
        # SLA RESPECT : Filter Function
        if ! singleton_methods.include? "sql_for_slas_sla_respect_#{sla_type.id}_field".to_sym
          define_singleton_method("sql_for_slas_sla_respect_#{sla_type.id}_field") do |field, operator, value|
            sql_for_slas_sla_respect_field(field,operator,value,sla_type.id)
          end
        end
      }
    end

  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = []
    @available_columns << QueryColumn.new(:project, :sortable => "#{Project.table_name}.name", :default_order => nil, :groupable => (project.nil??true:false) )
    @available_columns << QueryColumn.new(:issue, :sortable => "#{Issue.table_name}.id", :default_order => :desc, :groupable => false)
    @available_columns << QueryColumn.new(:sla_level, :sortable => "#{SlaLevel.table_name}.name", :default_order => nil, :groupable => true )
    @available_columns << QueryColumn.new(:start_date, :sortable => "#{SlaCache.table_name}.start_date", :default_order => nil, :groupable => false )
    @available_columns << QueryColumn.new(:created_on, :sortable => "#{SlaCache.table_name}.created_on", :default_order => nil, :groupable => false ) if User.current.admin?
    @available_columns << QueryColumn.new(:updated_on, :sortable => "#{SlaCache.table_name}.updated_on", :default_order => nil, :groupable => false )
    @available_columns << QueryAssociationColumn.new(:issue, :status, :caption => :field_status, :sortable => "#{IssueStatus.table_name}.position" )
    @available_columns << QueryAssociationColumn.new(:issue, :tracker, :caption => :field_tracker, :sortable => "#{Tracker.table_name}.position" )
    
    if ! project.nil?

      SlaType.joins(:sla_project_trackers).where("sla_project_trackers.project_id = ?", project.id).select("sla_types.id, sla_types.name").distinct.each { |sla_type|

        # SLA Term : Column
        name_to_sym = "get_sla_spent_#{sla_type.id}".to_sym
        get_sla_spent = QueryColumn.new(
          name_to_sym,
          :caption => "🚀 "+l(:label_sla_spent)+" "+sla_type.name,
          :groupable => false,
          :sortable => "(
            SELECT DISTINCT sla_cache_spents.spent
            FROM sla_caches
            LEFT JOIN sla_levels ON ( sla_caches.sla_level_id = sla_levels.id )
            LEFT JOIN custom_values ON ( sla_levels.custom_field_id = custom_values.custom_field_id AND custom_values.customized_id = sla_caches.issue_id )
            LEFT JOIN sla_cache_spents ON ( sla_caches.id = sla_cache_spents.sla_cache_id AND sla_cache_spents.sla_type_id = #{sla_type.id} )
            WHERE sla_caches.issue_id = issues.id            
          )"
        )
        # def get_sla_spent.group_by_statement
        #   self.sortable
        # end
        @available_columns << get_sla_spent

        # SLA Spent : Column
        name_to_sym = "get_sla_term_#{sla_type.id}".to_sym
        get_sla_term = QueryColumn.new(
          name_to_sym,
          :caption => "🏁 "+l(:label_sla_term)+" "+sla_type.name,
          :groupable => false,
          :sortable => "(
            SELECT DISTINCT sla_level_terms.term AS get_sla_term
            FROM issues AS sla_issues
            LEFT JOIN sla_caches ON ( sla_issues.id = sla_caches.issue_id )
            LEFT JOIN sla_levels ON ( sla_caches.sla_level_id = sla_levels.id )
            LEFT JOIN custom_values ON ( sla_levels.custom_field_id = custom_values.custom_field_id AND custom_values.customized_id = sla_issues.id )
            LEFT JOIN sla_level_terms ON ( sla_caches.sla_level_id = sla_level_terms.sla_level_id AND sla_level_terms.sla_type_id = #{sla_type.id}
              AND sla_level_terms.sla_priority_id = ( CASE
              WHEN sla_levels.custom_field_id IS NULL THEN sla_issues.priority_id
              ELSE CAST(custom_values.value AS BIGINT) END
              )
            )
            WHERE sla_caches.issue_id = issues.id            
          )"
        )
        # def get_sla_term.group_by_statement
        #   self.sortable
        # end
        @available_columns << get_sla_term
 
        # SLA Remain : Column
        name_to_sym = "get_sla_remain_#{sla_type.id}".to_sym
        get_sla_remain = QueryColumn.new(
          name_to_sym,
          :caption => "🏃 "+l(:label_sla_remain)+" "+sla_type.name,
          :groupable => false,
          :sortable => "(
            SELECT DISTINCT ( sla_level_terms.term - sla_cache_spents.spent ) AS get_sla_remain
            FROM issues AS sla_issues
            LEFT JOIN sla_caches ON ( sla_issues.id = sla_caches.issue_id )
            LEFT JOIN sla_levels ON ( sla_caches.sla_level_id = sla_levels.id )
            LEFT JOIN custom_values ON ( sla_levels.custom_field_id = custom_values.custom_field_id AND custom_values.customized_id = sla_issues.id )
            LEFT JOIN sla_cache_spents ON ( sla_caches.id = sla_cache_spents.sla_cache_id AND sla_cache_spents.sla_type_id = #{sla_type.id} )
            LEFT JOIN sla_level_terms ON ( sla_caches.sla_level_id = sla_level_terms.sla_level_id AND sla_level_terms.sla_type_id = #{sla_type.id}
              AND sla_level_terms.sla_priority_id = ( CASE
              WHEN sla_levels.custom_field_id IS NULL THEN sla_issues.priority_id
              ELSE CAST(custom_values.value AS BIGINT) END
              )
            )
            WHERE sla_issues.id = issues.id
          )",
        )
        # def get_sla_remain.group_by_statement
        #   self.sortable
        # end
        @available_columns << get_sla_remain

        # SLA Respect : Column
        name_to_sym = "get_sla_respect_#{sla_type.id}".to_sym
        get_sla_respect = QueryColumn.new(
          name_to_sym,
          :caption => "⏰ "+l(:label_sla_respect)+" "+sla_type.name,
          :groupable => false,
          :sortable => "(
            SELECT DISTINCT CASE
              WHEN sla_level_terms.term IS NULL THEN 0
              WHEN ( ( NOT ( sla_level_terms.term < sla_cache_spents.spent ) ) IS NOT TRUE ) THEN 1
              ELSE 2 END AS get_sla_respect
            FROM issues AS sla_issues
            LEFT JOIN sla_caches ON ( sla_issues.id = sla_caches.issue_id )
            LEFT JOIN sla_levels ON ( sla_caches.sla_level_id = sla_levels.id )
            LEFT JOIN custom_values ON ( sla_levels.custom_field_id = custom_values.custom_field_id AND custom_values.customized_id = sla_issues.id )
            LEFT JOIN sla_cache_spents ON ( sla_caches.id = sla_cache_spents.sla_cache_id AND sla_cache_spents.sla_type_id = #{sla_type.id} )
            LEFT JOIN sla_level_terms ON ( sla_caches.sla_level_id = sla_level_terms.sla_level_id AND sla_level_terms.sla_type_id = #{sla_type.id}
              AND sla_level_terms.sla_priority_id = ( CASE
              WHEN sla_levels.custom_field_id IS NULL THEN sla_issues.priority_id
              ELSE CAST(custom_values.value AS BIGINT) END
              )
            )
            WHERE sla_issues.id = issues.id
          )",
        )
        # def get_sla_respect.group_by_statement
        #   self.sortable
        # end
        @available_columns << get_sla_respect        

      }

    end

    @available_columns
  end

  def self.default(project: nil, user: User.current)
    # user default
    if user&.logged? && (query_id = user.pref.default_issue_query).present?
      query = find_by(id: query_id)
      return query if query&.visible?(user)
    end

    # project default
    query = project&.default_issue_query
    return query if query&.visibility == VISIBILITY_PUBLIC

    nil
  end

  def initialize(attributes=nil, *args)
    super attributes
    self.filters ||= {
    'issue.status_id' => {:operator => "o", :values => [""]}
    }
  end

  def default_columns_names
    super.presence || [
      "issue",
      "sla_level",
      "start_date",
      "updated_on",
    ].flat_map{|c| [c.to_s, c.to_sym]}
  end

  def sql_for_slas_sla_remain_field(field,operator,value,sla_type_id)
    condition =
      if ( operator == "!*" )
        "sla_level_terms.term IS NULL"
      elsif ( operator == "*" )
        "sla_level_terms.term IS NOT NULL"
      elsif ( operator == "><" && value.size == 2 )
        "( sla_level_terms.term - sla_cache_spents.spent ) BETWEEN #{value[0]} AND #{value[1]} "
      else
        "( sla_level_terms.term - sla_cache_spents.spent ) #{operator} #{value[0]} "
      end
    selection = "
      SELECT DISTINCT issues.id
      FROM issues AS sla_issues
      LEFT JOIN sla_caches ON ( sla_issues.id = sla_caches.issue_id )
      LEFT JOIN sla_levels ON ( sla_caches.sla_level_id = sla_levels.id )
      LEFT JOIN custom_values ON ( sla_levels.custom_field_id = custom_values.custom_field_id AND custom_values.customized_id = issues.id )
      LEFT JOIN sla_cache_spents ON ( sla_caches.id = sla_cache_spents.sla_cache_id AND sla_cache_spents.sla_type_id = #{sla_type_id} )
      LEFT JOIN sla_level_terms ON ( sla_caches.sla_level_id = sla_level_terms.sla_level_id AND sla_level_terms.sla_type_id = #{sla_type_id}
        AND sla_level_terms.sla_priority_id = ( CASE
        WHEN sla_levels.custom_field_id IS NULL THEN issues.priority_id
        ELSE CAST(custom_values.value AS BIGINT) END
        )
      )
      WHERE sla_issues.id = issues.id
    "
    "( #{Issue.table_name}.id = ( #{selection} AND #{condition} ) )"
  end  

  def sql_for_slas_sla_respect_field(field,operator,value,sla_type_id)
    condition =
      if value.size > 1
        ( operator == '!' ? 'sla_caches.sla_level_id IS NULL' : 'sla_caches.sla_level_id IS NOT NULL' )
      else
        is_done_val = value.join == '1' ? self.class.connection.quoted_true : self.class.connection.quoted_false
        "( ( NOT ( sla_level_terms.term < sla_cache_spents.spent ) ) IS #{is_done_val} )"
      end
    selection = "
      SELECT DISTINCT issues.id
      FROM issues AS sla_issues
      LEFT JOIN sla_caches ON ( sla_issues.id = sla_caches.issue_id )
      LEFT JOIN sla_levels ON ( sla_caches.sla_level_id = sla_levels.id )
      LEFT JOIN custom_values ON ( sla_levels.custom_field_id = custom_values.custom_field_id AND custom_values.customized_id = issues.id )
      LEFT JOIN sla_cache_spents ON ( sla_caches.id = sla_cache_spents.sla_cache_id AND sla_cache_spents.sla_type_id = #{sla_type_id} )
      LEFT JOIN sla_level_terms ON ( sla_caches.sla_level_id = sla_level_terms.sla_level_id AND sla_level_terms.sla_type_id = #{sla_type_id}
        AND sla_level_terms.sla_priority_id = ( CASE
        WHEN sla_levels.custom_field_id IS NULL THEN issues.priority_id
        ELSE CAST(custom_values.value AS BIGINT) END
        )
      )
      WHERE sla_issues.id = issues.id
    "
    "( #{Issue.table_name}.id = ( #{selection} AND #{condition} ) )"
  end  
    
  def sla_caches(options={})
    order_option = [group_by_sort_order, (options[:order] || sort_clause)].flatten.reject(&:blank?)

    scope = base_scope.
        includes(((options[:include] || [])).uniq).
        where(options[:conditions]).
        order(order_option).
        joins(joins_for_order_statement(order_option.join(','))).
        limit(options[:limit]).
        offset(options[:offset])

    sla_caches = scope.to_a
    sla_caches
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end
  
  # For Query Class
  def base_scope
    # self.queried_class.visible.where(statement)
    self.queried_class.visible.
    joins(:project,:issue).
      where(statement)
  end

  def results_scope(options={})
    order_option = [group_by_sort_order, (options[:order] || sort_clause)].flatten.reject(&:blank?)

    order_option << "#{self.queried_class.table_name}.id ASC"
    base_scope.
      order(order_option).
      joins(joins_for_order_statement(order_option.join(',')))
  end

  def sql_for_sla_level_id_field(field, operator, value)
    sql_for_field("sla_level_id", operator, value, SlaCache.table_name, "sla_level_id")
  end  

  def sql_for_issue_id_field(field, operator, value)
    self.class.queried_class = Issue
    sql_for_field("issue_id", operator, value, Issue.table_name, "id")
  ensure
    self.class.queried_class = SlaCache
  end

  def sql_for_issue_tracker_id_field(field, operator, value)
    self.class.queried_class = Issue
    sql_for_field("tracker_id", operator, value, Issue.table_name, "tracker_id")
  ensure
    self.class.queried_class = SlaCache
  end

  def sql_for_issue_status_id_field(field, operator, value)
    self.class.queried_class = Issue
    sql_for_field("status_id", operator, value, Issue.table_name, "status_id") # .gsub('sla_caches', 'issues')
  ensure
    self.class.queried_class = SlaCache
  end

  def joins_for_order_statement(order_options)
    joins = [super]
    if order_options
      if order_options.include?('issue_statuses')
        joins << "LEFT OUTER JOIN #{IssueStatus.table_name} ON #{IssueStatus.table_name}.id = #{Issue.table_name}.status_id"
      end
      if order_options.include?('trackers')
        joins << "LEFT OUTER JOIN #{Tracker.table_name} ON #{Tracker.table_name}.id = #{Issue.table_name}.tracker_id"
      end
    end

    joins.compact!
    joins.any? ? joins.join(' ') : nil
  end


  def all_sla_level_values
    return @all_sla_level_values if @all_sla_level_values

    values ||= []
    SlaLevel.pluck(:name,:id).map { |name,id|
      values << [name.to_s,id.to_s]
    }
    @all_sla_level_values = values
  end

end