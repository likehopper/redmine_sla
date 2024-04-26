class CreateSlaTypes < ActiveRecord::Migration[5.2]

  def change
    create_table :sla_types do |t|
      t.text :name, :null => false, index: { name: 'sla_types_name_ukey', unique: true }
    end
    say "Created table sla_types"
    
  end

end
