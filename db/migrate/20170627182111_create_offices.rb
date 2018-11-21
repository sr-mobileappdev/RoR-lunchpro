class CreateOffices < ActiveRecord::Migration[5.1]
  def change
    create_table :offices do |t|
      t.integer :status, default: 1
      t.string :name
      t.string :address_line1
      t.string :address_line2
      t.string :address_line3
      t.string :city
      t.string :state
      t.string :postal_code
      t.string :country
      t.float :lat
      t.float :lon
      t.integer :total_staff_count
      t.text :office_policy
      t.text :food_preferences
      t.text :delivery_instructions
      t.string :specialty
      t.string :timezone
      t.date :appointments_until
      t.integer :creating_sales_rep_id
      t.integer :created_by_id

      t.timestamps
    end
  end
end
