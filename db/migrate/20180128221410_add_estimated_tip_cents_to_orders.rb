class AddEstimatedTipCentsToOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :estimated_tip_cents, :integer
  end
end
