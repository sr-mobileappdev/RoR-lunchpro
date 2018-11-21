class RenameMenuItemMenus < ActiveRecord::Migration[5.1]
  def change
    rename_table :menu_item_menus, :menu_items_menus
    rename_column :menu_items_menus, :menu_type_id, :menu_id
  end
end
