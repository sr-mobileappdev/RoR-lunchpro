class RemoveExtraneousPackIndexOnLunchPacksMenuItems < ActiveRecord::Migration[5.1]
  def change
		remove_index :lunch_packs_menu_items, :lunch_pack_id
  end
end
