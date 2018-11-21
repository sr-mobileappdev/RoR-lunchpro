class RenameIndexRestaurantPocOnRestaurantId < ActiveRecord::Migration[5.1]
  def change
    remove_index :restaurant_pocs, :restaurant_id
    add_index :restaurant_pocs, :restaurant_id
  end
end
