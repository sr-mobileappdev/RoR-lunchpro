class CreateRestaurantTransactions < ActiveRecord::Migration[5.1]
  def change
    create_table :restaurant_transactions do |t|
      t.integer :bank_account_id
      t.integer :restaurant_id
      t.integer :due_amount_cents
      t.integer :paid_amount_cents
      t.integer :status, default: 1
      t.text :notes
      t.integer :created_by_id
      t.integer :processed_by_id
      t.integer :cancelled_by_id
      t.datetime :processed_at
      t.datetime :cancelled_at

      t.timestamps
    end
  end
end
