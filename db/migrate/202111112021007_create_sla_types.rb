# File: redmine_sla/db/migrate/202111112021007_create_sla_types.rb
# Purpose:
#   Create the `sla_types` table, which stores the different SLA categories/types.
#   These types can be used to group SLAs (e.g. "Response time", "Resolution time")
#   and may be referenced by other SLA-related entities.

class CreateSlaTypes < ActiveRecord::Migration[5.2]

  def change
    create_table :sla_types do |t|

      # SLA type name, must be unique across all SLA types
      t.text :name, null: false,
                    index: { name: 'sla_types_name_ukey', unique: true }
    end

    # Migration log output
    say "Created table sla_types"
  end

end