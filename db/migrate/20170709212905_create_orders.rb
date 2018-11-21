class CreateOrders < ActiveRecord::Migration[5.1]
  def change
    create_table :orders do |t|
      t.references :sales_rep
      t.references :appointment
      t.references :restaurant
      t.string :order_number
      t.text :rep_notes
      t.text :restaurant_notes
      t.integer :subtotal
      t.integer :sales_tax
      t.integer :delivery_cost
      t.integer :lunchpro_commission
      t.integer :processing_fee
      t.integer :tip
      t.integer :total
      t.boolean :funds_reserved
      t.boolean :funds_funded
      t.references :created_by_user
      t.string :driver_name
      t.string :driver_phone

      t.timestamps
    end
  end
end
