class AddRecommendedByIdToOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :recommended_by_id, :integer
  end
end
