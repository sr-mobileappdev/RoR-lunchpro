class RemoveFkFromLunchPacksMenuItems < ActiveRecord::Migration[5.1]
  def change
		remove_foreign_key :lunch_packs_menu_items, :lunch_packs
		remove_foreign_key :lunch_packs_menu_items, :menu_items
  end
end
