class AddTransactionTypeToOrderTransactions < ActiveRecord::Migration[5.1]
  def change
    add_column :order_transactions, :transaction_type, :integer
  end
end
