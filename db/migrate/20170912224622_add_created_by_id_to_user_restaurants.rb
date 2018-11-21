class AddCreatedByIdToUserRestaurants < ActiveRecord::Migration[5.1]
  def change
    add_column :user_restaurants, :created_by_id, :integer
  end
end
