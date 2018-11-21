class AddMenuItemIdToMenuItemImages < ActiveRecord::Migration[5.1]
  def change
    add_column :menu_item_images, :menu_item_id, :integer
  end
end
