class CreateSlas < ActiveRecord::Migration[5.2]

  def change
    create_table :slas do |t|
      t.text :name, :null => false, index: { name: 'slas_name_ukey', unique: true}
    end
    say "Created table slas"
  end

end
