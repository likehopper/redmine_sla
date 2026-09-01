# File: redmine_sla/db/migrate/202111112021013_create_sla_view_journal_statuses.rb
# Purpose:
#   Deploy the SQL view `sla_view_journal_statuses`, which normalizes issue
#   status changes extracted from Redmine journals. The view definition is
#   stored per-dialect under `db/sql_views/<adapter>/sla_view_journal_statuses.sql`
#   and loaded using a reversible migration so it can be dropped cleanly on rollback.

class CreateSlaViewJournalStatuses < ActiveRecord::Migration[5.2]

  def change

    reversible do |dir|

      dir.up do
        # Create the SQL view from the dialect-specific SQL file
        execute RedmineSla::DbDialect.view_sql('sla_view_journal_statuses')
        say "Created view sla_view_journal_statuses"
      end

      dir.down do
        # Drop the view when rolling back the migration
        if RedmineSla::DbDialect.adapter == :mysql
          execute "DROP VIEW IF EXISTS sla_view_journal_statuses ;"
        else
          execute "DROP VIEW IF EXISTS public.sla_view_journal_statuses CASCADE ;"
        end
        say "Dropped view sla_view_journal_statuses"
      end

    end

  end

end