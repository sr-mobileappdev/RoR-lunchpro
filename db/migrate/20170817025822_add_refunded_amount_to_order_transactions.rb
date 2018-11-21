class AddRefundedAmountToOrderTransactions < ActiveRecord::Migration[5.1]
  def change
    add_column :order_transactions, :refunded_amount, :bigint
  end
end
