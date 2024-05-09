class CreateSlaLevelTerms < ActiveRecord::Migration[5.2]

  def change
    create_table :sla_level_terms do |t|
      t.belongs_to :sla_level, :null => false, foreign_key: { name: 'sla_levels_sla_level_terms_fkey', on_delete: :cascade }
      t.belongs_to :sla_type, :null => false, foreign_key: { name: 'sla_level_terms_sla_types_fkey', on_delete: :cascade }
      t.bigint :sla_priority_id, :null => false, \
        comment: "Pivot value used for priority or enumeration"
      t.belongs_to :custom_field_enumeration, :null => true, foreign_key: { name: 'sla_level_terms_custom_field_enumeration_fkey', on_delete: :cascade }, \
        comment: "The value is managed in the model to ensure cascading deletion in case of custom_field_enumeration deletion"
      t.belongs_to :priority, :null => true, foreign_key: { name: 'sla_level_terms_priority_id_fkey', on_delete: :cascade, to_table: :enumerations }, \
        comment: "The value is managed in the model to ensure cascading deletion in case of enumeration deletion"
      t.integer :term, :null => false, \
        comment: "Stores the term value in minutes"
    end
    say "Created table sla_level_terms"

    add_index :sla_level_terms, [:sla_level_id, :sla_type_id, :sla_priority_id ], :unique => true, name: 'sla_level_sla_level_terms_sla_priority_id_ukey'
    say "Created index unique sla_level_sla_level_terms_sla_priority_id_ukey"
       
  end

end
