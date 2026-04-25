# frozen_string_literal: true

# File: redmine_sla/test/unit/sla_plugin_version_test.rb
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

require File.expand_path('../../application_sla_units_test_case', __FILE__)

class SlaPluginVersionTest < ApplicationSlaUnitsTestCase

  PLUGIN_ID      = :redmine_sla
  CHANGELOG_PATH = File.expand_path('../../CHANGELOG.md', __dir__)
  SEMVER_FORMAT  = /\A\d+\.\d+\.\d+\z/

  # --- Format ---

  test "RedmineSla::Version is a non-empty string" do
    assert_kind_of String, RedmineSla::Version
    assert_not RedmineSla::Version.empty?
  end

  test "RedmineSla::Version follows semver format X.Y.Z" do
    assert_match SEMVER_FORMAT, RedmineSla::Version,
      "Version '#{RedmineSla::Version}' does not match expected semver format X.Y.Z"
  end

  # --- Plugin registration consistency ---

  test "Redmine plugin registry exposes the same version as RedmineSla::Version" do
    plugin = Redmine::Plugin.find(PLUGIN_ID)
    assert_not_nil plugin, "Plugin :#{PLUGIN_ID} is not registered"
    assert_equal RedmineSla::Version, plugin.version,
      "init.rb registers version '#{plugin.version}' but RedmineSla::Version is '#{RedmineSla::Version}'"
  end

  test "plugin is registered with the expected id :redmine_sla" do
    assert_nothing_raised { Redmine::Plugin.find(PLUGIN_ID) }
  end

  # --- CHANGELOG consistency ---
  # The rule: before bumping version.rb you must add a ## X.Y.Z section in CHANGELOG.
  # This test enforces that contract: if RedmineSla::Version does not appear in
  # CHANGELOG.md, the bump was done without documenting the release.

  test "CHANGELOG.md contains a section for the declared version" do
    assert File.exist?(CHANGELOG_PATH),
      "CHANGELOG.md not found at #{CHANGELOG_PATH}"

    changelog = File.read(CHANGELOG_PATH)
    pattern   = /^## #{Regexp.escape(RedmineSla::Version)}(\s|\z)/

    assert_match pattern, changelog,
      "CHANGELOG.md has no '## #{RedmineSla::Version}' section — " \
      "add a release entry before bumping version.rb"
  end

  # Guard: CHANGELOG top-listed version must be >= declared version.
  # Catches the case where version.rb was bumped past the latest CHANGELOG entry.
  test "RedmineSla::Version does not exceed the latest version in CHANGELOG.md" do
    assert File.exist?(CHANGELOG_PATH), "CHANGELOG.md not found at #{CHANGELOG_PATH}"

    changelog  = File.read(CHANGELOG_PATH)
    top_match  = changelog.match(/^## (\d+\.\d+\.\d+)/)
    assert_not_nil top_match, "No semver version header found in CHANGELOG.md"

    top_version      = Gem::Version.new(top_match[1])
    declared_version = Gem::Version.new(RedmineSla::Version)

    assert declared_version <= top_version,
      "RedmineSla::Version (#{RedmineSla::Version}) exceeds the latest CHANGELOG entry " \
      "(#{top_match[1]}) — add a CHANGELOG section for the new version"
  end

end
