# File: redmine_sla/db/migrate/202111112021020_add_position_to_sla_types.rb
# Purpose:
#   Add a `position` column to `sla_types`, giving admins control over the
#   display order of SLA types wherever they appear as columns (issue view
#   gauges, issue/time-entry list columns, the SLA level terms matrix)
#   instead of the incidental creation order they've had until now.

class AddPositionToSlaTypes < ActiveRecord::Migration[5.2]

  def up
    add_column :sla_types, :position, :integer

    # Plugin models aren't safely loadable from within a migration (unlike
    # Redmine core's own migrations, which can reference core models like
    # IssueStatus directly) -- every other migration in this plugin sticks
    # to raw SQL for exactly that reason, so this backfill does too.
    execute <<~SQL
      UPDATE sla_types
      SET position = ranked.rn
      FROM (SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS rn FROM sla_types) AS ranked
      WHERE sla_types.id = ranked.id
    SQL

    say "Added and backfilled sla_types.position"
  end

  def down
    remove_column :sla_types, :position
  end

end
