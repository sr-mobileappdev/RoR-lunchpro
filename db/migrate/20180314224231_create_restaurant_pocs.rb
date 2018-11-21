class CreateRestaurantPocs < ActiveRecord::Migration[5.1]
  def change
    create_table :restaurant_pocs do |t|
      t.bigint :restaurant_id
      t.string :first_name
      t.string :last_name
      t.string :title
      t.string :phone
      t.string :email
      t.integer :created_by_id
      t.integer :status, default: 1
      t.index :restaurant_id, name: "index_restaurant_poc_on_restaurant_id"

      t.timestamps
    end
  end
end
