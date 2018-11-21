class AddIdempotencyKeyToOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :idempotency_key, :uuid
  end
end
