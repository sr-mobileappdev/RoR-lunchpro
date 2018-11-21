class CreateOrderTransactions < ActiveRecord::Migration[5.1]
  def change
    create_table :order_transactions do |t|
      t.references :payment, foreign_key: true
      t.references :order, foreign_key: true
      t.integer :authorized_amount
      t.integer :captured_amount
      t.string :transaction_identifier
      t.integer :status
      t.string :error_message

      t.timestamps
    end
  end
end
