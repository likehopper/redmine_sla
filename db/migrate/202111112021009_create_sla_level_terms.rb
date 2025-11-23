# File: redmine_sla/db/migrate/202111112021009_create_sla_level_terms.rb
# Purpose:
#   Create the `sla_level_terms` table, which defines rule terms attached to
#   a specific SLA level. A term represents a condition that depends on:
#     - an SLA level,
#     - an SLA type,
#     - a priority pivot (priority or custom_field_enumeration),
#     - and a numeric term value expressed in minutes.
#
#   These terms allow SLA levels to behave differently depending on priorities
#   or custom field enumerations.

class CreateSlaLevelTerms < ActiveRecord::Migration[5.2]

  def change
    create_table :sla_level_terms do |t|

      # Link to the SLA level to which this term belongs
      t.belongs_to :sla_level,
                   null: false,
                   foreign_key: {
                     name: 'sla_levels_sla_level_terms_fkey',
                     on_delete: :cascade
                   }

      # Link to the SLA type used by this term
      t.belongs_to :sla_type,
                   null: false,
                   foreign_key: {
                     name: 'sla_level_terms_sla_types_fkey',
                     on_delete: :cascade
                   }

      # Pivot value used for priority or enumeration
      # (this value determines which "branch" of a level term is used)
      t.bigint :sla_priority_id, null: false

      # Optional link to a custom field enumeration.
      # The model ensures cascading deletion when a CF enumeration is removed.
      t.belongs_to :custom_field_enumeration,
                   null: true,
                   foreign_key: {
                     name: 'sla_level_terms_custom_field_enumeration_fkey',
                     on_delete: :cascade
                   }

      # Optional link to a Redmine core enumeration (priority).
      # The model ensures cascading deletion when a priority enumeration is removed.
      t.belongs_to :priority,
                   null: true,
                   foreign_key: {
                     name: 'sla_level_terms_priority_id_fkey',
                     on_delete: :cascade,
                     to_table: :enumerations
                   }

      # Term duration in minutes for this level/type/priority combination
      t.integer :term, null: false
    end

    # Migration log output
    say "Created table sla_level_terms"

    # Ensure unique combination of level, type and pivot priority
    add_index :sla_level_terms,
              [:sla_level_id, :sla_type_id, :sla_priority_id],
              unique: true,
              name: 'sla_level_sla_level_terms_sla_priority_id_ukey'
    say "Created index unique sla_level_sla_level_terms_sla_priority_id_ukey"

  end

end