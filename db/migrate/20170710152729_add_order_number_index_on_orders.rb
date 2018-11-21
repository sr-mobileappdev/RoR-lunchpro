class AddOrderNumberIndexOnOrders < ActiveRecord::Migration[5.1]
  def change
		add_index :orders, :order_number
  end
end
