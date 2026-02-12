# frozen_string_literal: true

# File: redmine_sla/test/documentation/sla_creation_documentation_test.rb
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

require_relative "../application_sla_documentation_test_case"

require_relative "modules/00_all_modules"

class SlaRunTest < ApplicationSlaDocumentationTestCase

  include RedmineSlaDocumentationModules

  setup do
    load_doc_fixtures!(suite: ENV["SUITE"] || "default")
  end

  def load_doc_fixtures!(suite: ENV["SUITE"] || "default")
    @fixtures = doc_fixtures(suite: suite)
  end

  def doc_fixtures(suite: ENV["SUITE"] || "default")
    suite = suite.to_s.strip
    suite = "default" if suite.empty?

    @doc_fixtures_cache ||= {}
    return @doc_fixtures_cache[suite] if @doc_fixtures_cache.key?(suite)

    base = Rails.root.join("plugins", "redmine_sla", "test", "documentation")
    dir  = base.join(suite)
    dir  = base.join("default") unless Dir.exist?(dir)

    raise ArgumentError, "Fixtures folder not found for SUITE=#{suite} (expected #{base}/<suite>)" unless Dir.exist?(dir)

    fixtures = {}

    Dir[dir.join("*.yml").to_s].sort.each do |path|
      key  = File.basename(path, ".yml")
      data = YAML.load_file(path)

      unless data.is_a?(Hash) && data.key?(key)
        raise KeyError, "Invalid YAML #{path}: expected root key '#{key}'"
      end

      fixtures[key] = data[key]
    end

    @doc_fixtures_cache[suite] = fixtures
  end

  def fixture!(key)
    key = key.to_s
    raise "Fixtures not loaded. load_doc_fixtures! must be called in setup." unless @fixtures.is_a?(Hash)

    return @fixtures[key] if @fixtures.key?(key)

    raise KeyError, "Unknown fixture '#{key}'. Available: #{@fixtures.keys.sort.join(', ')}"
  end  

end