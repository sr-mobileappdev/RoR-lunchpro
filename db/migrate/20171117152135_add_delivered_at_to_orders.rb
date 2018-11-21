class AddDeliveredAtToOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :delivered_at, :datetime
    add_column :orders, :delivery_arrived_at, :datetime
    add_column :orders, :completed_at, :datetime
  end
end
