class CreateSlaLevelTerms < ActiveRecord::Migration[5.2]

  def change
    create_table :sla_level_terms do |t|
      t.belongs_to :sla_level, :null => false, foreign_key: { on_delete: :cascade }
      t.belongs_to :sla_type, :null => false, foreign_key: { on_delete: :cascade }
      t.integer :priority_id, :null => false
      t.integer :term, :null => false
    end
    say "Created table sla_level_terms"

    add_index :sla_level_terms, [:sla_level_id, :sla_type_id, :priority_id ], :unique => true, name: 'sla_level_terms_ukey'
    say "Created index unique sla_level_terms_ukey"
       
  end

end
