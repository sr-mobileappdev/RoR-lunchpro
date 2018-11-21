class RenameMenuItemsTypes < ActiveRecord::Migration[5.1]
  def change
    rename_table :menu_items_types, :menu_item_menus
  end
end
