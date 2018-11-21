class AddOfficeIdToOrderReview < ActiveRecord::Migration[5.1]
  def change
    add_column :order_reviews, :reviewer_id, :integer
    add_column :order_reviews, :reviewer_type, :integer
    add_column :order_reviews, :created_by_id, :integer
  end
end
