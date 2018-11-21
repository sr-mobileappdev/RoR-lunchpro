class CreateLunchPacks < ActiveRecord::Migration[5.1]
  def change
    create_table :lunch_packs do |t|
      t.string :name
      t.text :description
      t.integer :wholesale_price
      t.integer :retail_price
      t.integer :status
      t.bigint :ordered_counter

      t.timestamps
    end
  end
end
