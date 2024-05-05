class CreateSlaLevelTerms < ActiveRecord::Migration[5.2]

  def change
    create_table :sla_level_terms do |t|
      t.belongs_to :sla_level, :null => false, foreign_key: { name: 'sla_levels_sla_level_terms_fkey', on_delete: :cascade }
      t.belongs_to :sla_type, :null => false, foreign_key: { name: 'sla_level_terms_sla_types_fkey', on_delete: :cascade }
      t.text :priority, :null => false
      t.integer :term, :null => false
    end
    say "Created table sla_level_terms"

    add_index :sla_level_terms, [:sla_level_id, :sla_type_id, :priority ], :unique => true, name: 'sla_level_terms_ukey'
    say "Created index unique sla_level_terms_ukey"
       
  end

end
