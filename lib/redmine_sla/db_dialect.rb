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
  end
end
