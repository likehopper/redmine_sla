# File: redmine_sla/db/migrate/202111112021017_create_sla_view_roll_statuses.rb
# Purpose:
#   Deploy the SQL view `sla_view_roll_statuses`, which rebuilds issue status
#   intervals (from/to status + dates) from the normalized journal data.
#   The view definition is stored in `db/sql_views/sla_view_roll_statuses.sql`
#   and is loaded in a reversible way so it can be cleanly dropped on rollback.

class CreateSlaViewRollStatuses < ActiveRecord::Migration[5.2]

  def change

    reversible do |dir|
    
      dir.up do
        # Create the SQL view from the dedicated SQL file
        execute File.read(
          File.expand_path('../../sql_views/sla_view_roll_statuses.sql', __FILE__)
        )
        say "Created view sla_view_roll_statuses"
      end

      dir.down do
        # Drop the view when rolling back the migration
        execute "DROP VIEW IF EXISTS public.sla_view_roll_statuses CASCADE ;"
        say "Dropped view sla_view_roll_statuses"
      end
      
    end
    
  end

end
