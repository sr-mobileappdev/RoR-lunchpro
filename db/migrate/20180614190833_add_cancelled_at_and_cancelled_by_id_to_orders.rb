class AddCancelledAtAndCancelledByIdToOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :cancelled_at, :timestamp
    add_column :orders, :cancelled_by_id, :integer
  end
end
