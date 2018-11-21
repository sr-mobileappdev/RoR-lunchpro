class AddUpdatedByIdToOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :updated_by_id, :integer
  end
end
