class CreateJoinTableMenuItemsMenuTypes < ActiveRecord::Migration[5.1]
  def change
    create_join_table :menu_items, :menu_types do |t|
      t.index [:menu_item_id, :menu_type_id]
      # t.index [:menu_type_id, :menu_item_id]
    end
  end
end
