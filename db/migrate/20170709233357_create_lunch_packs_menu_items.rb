class CreateLunchPacksMenuItems < ActiveRecord::Migration[5.1]
  def change
    create_table :lunch_packs_menu_items do |t|
      t.references :lunch_pack, foreign_key: true
      t.references :menu_item, foreign_key: true
      t.integer :sort_order

      t.timestamps
			t.index [:lunch_pack_id, :menu_item_id]
    end
  end
end
