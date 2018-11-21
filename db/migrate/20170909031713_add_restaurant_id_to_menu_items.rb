class AddRestaurantIdToMenuItems < ActiveRecord::Migration[5.1]
  def change
    add_column :menu_items, :restaurant_id, :integer
    add_column :menu_types, :restaurant_id, :integer
    rename_table :menu_types, :menus
  end
end
