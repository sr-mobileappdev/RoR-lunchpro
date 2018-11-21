class AddOverallToOrderReviews < ActiveRecord::Migration[5.1]
  def change
    add_column :order_reviews, :overall, :integer
  end
end
