class CreateSlaTypes < ActiveRecord::Migration[5.2]

  def change
    create_table :sla_types do |t|
      t.text :name, :null => false, index: { unique: true }
    end
    say "Created table sla_types"
    
  end

end
