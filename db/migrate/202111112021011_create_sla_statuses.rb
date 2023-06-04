class CreateSlaStatuses < ActiveRecord::Migration[5.2]

  def change
    create_table :sla_statuses do |t|
      t.belongs_to :status,
        references: :IssueStatuses,
        foreign_key: { on_delete: :cascade, to_table: :issue_statuses }
      t.belongs_to :sla_type, foreign_key: { on_delete: :cascade }
    end
    say "Created table sla_level_terms"

    add_index :sla_statuses, [:status_id, :sla_type_id ], :unique => true, name: 'sla_statuses_ukey'
    say "Created index unique sla_statuses_ukey"
  
  end

end
