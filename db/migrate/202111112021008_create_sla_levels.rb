# File: redmine_sla/db/migrate/202111112021008_create_sla_levels.rb
# Purpose:
#   Create the `sla_levels` table. An SLA level is a rule definition that combines:
#     - a name,
#     - an associated SLA,
#     - an SLA calendar,
#     - an optional custom field.
#
#   SLA levels represent different “steps” inside an SLA structure and may be used
#   to determine applied rules, conditions, or field-driven logic. This table
#   contains only relational definitions (no durations), which aligns with this
#   plugin’s data model architecture.

class CreateSlaLevels < ActiveRecord::Migration[5.2]

  def change
    create_table :sla_levels do |t|

      # Level name (must be unique)
      t.text :name, null: false,
                    index: { name: 'sla_levels_name_ukey', unique: true }

      # Link to the parent SLA
      t.belongs_to :sla,
                   foreign_key: {
                     name: 'sla_levels_slas_fkey',
                     on_delete: :cascade
                   }

      # Link to the SLA calendar defining when this level applies
      t.belongs_to :sla_calendar,
                   foreign_key: {
                     name: 'sla_levels_sla_calendars_fkey',
                     on_delete: :cascade
                   }

      # Optional link to a Redmine custom field
      t.belongs_to :custom_field,
                   default: nil,
                   null: true,
                   foreign_key: {
                     name: 'sla_levels_custom_fields_fkey',
                     on_delete: :cascade
                   }

      # Note:
      #   The comment at the end of the line indicates that this used to include
      #   explicit `to_table`/`column` definitions, but they are unnecessary
      #   since `belongs_to :custom_field` already targets the correct table.
    end

    # Migration log output
    say "Created table sla_levels"
  end

end