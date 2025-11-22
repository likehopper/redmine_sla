# File: redmine_sla/db/migrate/202111112021011_create_sla_get_date.rb
# Purpose:
#   Deploy the PostgreSQL function `sla_get_date`, which normalizes timestamps
#   according to the configured SLA timezone and truncates them to the minute.
#   The function is stored in `db/sql_functions/sla_get_date.sql` and loaded
#   using a reversible migration so the function can be cleanly removed on rollback.

class CreateSlaGetDate < ActiveRecord::Migration[5.2]

  def change

    reversible do |dir|
      
      dir.up do
        # Execute the SQL function definition from the SQL file
        execute File.read(
          File.expand_path('../../sql_functions/sla_get_date.sql', __FILE__)
        )
        say "Created function sla_get_date"
      end

      dir.down do
        # Remove the function if the migration is rolled back
        execute "DROP FUNCTION IF EXISTS public.sla_get_date CASCADE ;"
        say "Dropped function sla_get_date"
      end

    end

  end

end