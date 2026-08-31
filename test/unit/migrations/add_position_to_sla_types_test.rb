# frozen_string_literal: true

# File: redmine_sla/test/unit/migrations/add_position_to_sla_types_test.rb
# Purpose: exercise the real upgrade path with rows created before position
# exists, rather than only inspecting an already migrated test database.

require File.expand_path('../../../application_sla_units_test_case', __FILE__)
require Rails.root.join('plugins/redmine_sla/db/migrate/202111112021020_add_position_to_sla_types')

class AddPositionToSlaTypesTest < ApplicationSlaUnitsTestCase
  test "upgrade backfills existing SLA types in id order" do
    connection = ActiveRecord::Base.connection
    migration = AddPositionToSlaTypes.new
    names = 3.times.map { |index| "Pre-migration type #{index} #{SecureRandom.hex(4)}" }

    migration.migrate(:down) if connection.column_exists?(:sla_types, :position)
    names.each do |name|
      connection.execute(
        "INSERT INTO sla_types (name) VALUES (#{connection.quote(name)})"
      )
    end
    expected_ids = connection.select_values(
      "SELECT id FROM sla_types ORDER BY id"
    ).map(&:to_i)

    migration.migrate(:up)
    actual = connection.select_rows(
      "SELECT id, position FROM sla_types ORDER BY id"
    ).map { |id, position| [id.to_i, position.to_i] }

    assert_equal expected_ids.zip(1..expected_ids.length), actual
    assert_not connection.columns(:sla_types).find { |column| column.name == 'position' }.null
  ensure
    migration&.migrate(:up) unless connection&.column_exists?(:sla_types, :position)
  end
end
