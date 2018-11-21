class AddPaymentMethodIdToOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :payment_method_id, :integer
  end
end
