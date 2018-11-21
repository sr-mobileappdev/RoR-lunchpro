class ChangeReviewerTypeToString < ActiveRecord::Migration[5.1]
  def change
    remove_column :order_reviews, :reviewer_type
    add_column :order_reviews, :reviewer_type, :string
  end
end
