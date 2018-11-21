class AddRestaurantIdToLunchPacks < ActiveRecord::Migration[5.1]
  def change
    add_column :lunch_packs, :restaurant_id, :integer
  end
end
