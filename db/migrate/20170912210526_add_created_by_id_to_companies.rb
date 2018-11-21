class AddCreatedByIdToCompanies < ActiveRecord::Migration[5.1]
  def change
    add_column :companies, :created_by_id, :integer
    add_column :companies, :status, :integer
    add_column :order_reviews, :status, :integer
  end
end
