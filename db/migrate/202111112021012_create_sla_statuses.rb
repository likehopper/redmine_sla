# File: redmine_sla/db/migrate/202111112021012_create_sla_statuses.rb
# Purpose:
#   Create the `sla_statuses` table, which links Redmine issue statuses to SLA
#   types. This mapping is used to determine, for each status, how it should
#   behave from an SLA perspective (for example: count time, pause, stop, etc.,
#   depending on the associated SLA type).

class CreateSlaStatuses < ActiveRecord::Migration[5.2]

  def change
    create_table :sla_statuses do |t|

      # Reference to the Redmine issue status (from `issue_statuses` table)
      t.belongs_to :status,
        references: :IssueStatuses,
        foreign_key: {
          name: 'sla_statuses_issue_statuses_fkey',
          on_delete: :cascade,
          to_table: :issue_statuses
        }

      # Reference to the SLA type used to categorize the behavior of this status
      t.belongs_to :sla_type,
        foreign_key: {
          name: 'sla_statuses_sla_types_fkey',
          on_delete: :cascade
        }
    end

    # Migration log message (kept as-is, even if the wording mentions "sla_level_terms")
    say "Created table sla_level_terms"

    # Ensure that a given (status_id, sla_type_id) pair is unique
    add_index :sla_statuses,
              [:status_id, :sla_type_id],
              unique: true,
              name: 'sla_statuses_ukey'
    say "Created index unique sla_statuses_ukey"
  
  end

end