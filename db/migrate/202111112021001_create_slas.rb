# File: redmine_sla/db/migrate/202111112021001_create_slas.rb
# Purpose:
#   Define the base "slas" table, which stores the main SLA entities used
#   by the plugin (name and unique constraint). Other SLA-related tables
#   reference this one.

class CreateSlas < ActiveRecord::Migration[5.2]

  def change
    create_table :slas do |t|
      # SLA display name, required and unique across all SLAs
      # (string rather than text: MySQL/MariaDB cannot put a unique index on
      # a full TEXT column without a key-length prefix)
      t.string :name, limit: 255, null: false, index: { name: 'slas_name_ukey', unique: true }
    end

    # Migration log message shown when the table is created
    say "Created table slas"
  end

end