class CreateDrugs < ActiveRecord::Migration[5.1]
  def change
    create_table :drugs do |t|
      t.string :brand
      t.string :generic_name

      t.timestamps
    end
  end
end
