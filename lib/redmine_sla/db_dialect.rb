# frozen_string_literal: true

# File: redmine_sla/lib/redmine_sla/db_dialect.rb
# Purpose:
#   PostgreSQL and MySQL/MariaDB require different SQL for the plugin's
#   stored functions and views (window functions, generate_series, composite
#   return types, ...). This module resolves the active database adapter and
#   loads the matching SQL file from db/sql_functions/<adapter>/ or
#   db/sql_views/<adapter>/, so migrations stay adapter-agnostic.

module RedmineSla
  module DbDialect
    class UnsupportedAdapterError < StandardError; end

    SQL_FUNCTIONS_ROOT = File.expand_path('../../../db/sql_functions', __FILE__)
    SQL_VIEWS_ROOT = File.expand_path('../../../db/sql_views', __FILE__)

    def self.adapter
      case ActiveRecord::Base.connection.adapter_name
      when /postgresql/i
        :postgresql
      when /mysql/i, /trilogy/i
        :mysql
      else
        raise UnsupportedAdapterError,
          "Redmine SLA does not support the '#{ActiveRecord::Base.connection.adapter_name}' database adapter"
      end
    end

    def self.function_sql(name)
      read_sql(SQL_FUNCTIONS_ROOT, name)
    end

    def self.view_sql(name)
      read_sql(SQL_VIEWS_ROOT, name)
    end

    def self.read_sql(root, name)
      File.read(File.join(root, adapter.to_s, "#{name}.sql"))
    end

    # MySQL/MariaDB's CAST() has no BIGINT target type (use SIGNED instead);
    # PostgreSQL's CAST() has no SIGNED target type (use BIGINT instead).
    def self.bigint_cast_type
      adapter == :mysql ? 'SIGNED' : 'BIGINT'
    end

    # PostgreSQL's default collation compares text byte-for-byte (case
    # sensitive); MySQL/MariaDB's default collation (*_ai_ci) is case- and
    # accent-insensitive. Wrap a column reference with this so ORDER BY on
    # free-text columns sorts consistently across both engines.
    def self.case_sensitive_order(column_expr)
      adapter == :mysql ? "BINARY #{column_expr}" : column_expr
    end

    # Value large enough to cover the widest window the SQL functions'
    # own sanity ceiling allows (100000 days), with headroom.
    RECURSION_DEPTH_LIMIT = 100_100

    # MySQL/MariaDB cap recursive CTE depth at 1000 by default: MySQL raises
    # ER_CTE_RECURSION_LIMIT past that, MariaDB instead silently truncates
    # the result with only a warning. sla_get_level/sla_get_level_overlap/
    # sla_get_spent rely on deeper recursion for anything beyond a ~2.7-year
    # window, so the cap must be raised before they run.
    #
    # This can't live inside those stored FUNCTIONs: the session variable
    # controlling it is named differently per engine (cte_max_recursion_depth
    # on MySQL, max_recursive_iterations on MariaDB), and picking between
    # them needs dynamic SQL (PREPARE/EXECUTE), which MySQL/MariaDB disallow
    # inside a FUNCTION (only a PROCEDURE may use it) -- and even a SET
    # statement naming the *other* engine's variable inside a dead branch
    # (`IF ... THEN ... ELSE ... END IF`) still fails MariaDB's CREATE
    # FUNCTION, which validates every SET target eagerly rather than only
    # when that branch actually runs. So this is set here instead, from
    # Ruby, once per physical connection, before any of those functions run.
    def self.ensure_recursion_depth!
      return unless adapter == :mysql

      connection = ActiveRecord::Base.connection
      return if connection.instance_variable_get(:@redmine_sla_recursion_depth_set)

      variable = connection.select_value('SELECT VERSION()').to_s.include?('MariaDB') ? 'max_recursive_iterations' : 'cte_max_recursion_depth'
      connection.execute("SET SESSION #{variable} = #{RECURSION_DEPTH_LIMIT}")
      connection.instance_variable_set(:@redmine_sla_recursion_depth_set, true)
    end
  end
end
