class CreateRestaurants < ActiveRecord::Migration[5.1]
  def change
    create_table :restaurants do |t|
      t.integer :status, default: 1
      t.string :name
      t.text :description
      t.string :address_line1
      t.string :address_line2
      t.string :address_line3
      t.string :city
      t.string :state
      t.string :postal_code
      t.string :country
      t.float :lat
      t.float :lon
      t.integer :min_order_amount
      t.integer :max_order_people
      t.integer :default_delivery_fee
      t.date :orders_until_date
      t.integer :orders_until_hour
      t.string :timezone
      t.integer :created_by_id

      t.timestamps
    end
  end
end
