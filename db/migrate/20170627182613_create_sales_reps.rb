class CreateSalesReps < ActiveRecord::Migration[5.1]
  def change
    create_table :sales_reps do |t|
      t.integer :status, default: 1
      t.integer :user_id
      t.string :first_name
      t.string :last_name
      t.string :address_line1
      t.string :address_line2
      t.string :address_line3
      t.string :city
      t.string :state
      t.string :postal_code
      t.string :country
      t.integer :company_id
      t.integer :default_tip_percent
      t.integer :max_tip_amount
      t.integer :per_person_budget
      t.string :timezone
      t.integer :created_by_id

      t.timestamps
    end
  end
end
