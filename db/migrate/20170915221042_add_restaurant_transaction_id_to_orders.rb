class AddRestaurantTransactionIdToOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :restaurant_transaction_id, :integer
  end
end
