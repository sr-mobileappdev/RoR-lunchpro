class RenameOrderTransactionPaymentIdToPaymentMethodId < ActiveRecord::Migration[5.1]
  def change
  	rename_column :order_transactions, :payment_id, :payment_method_id
  end
end
