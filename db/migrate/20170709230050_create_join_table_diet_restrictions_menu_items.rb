class CreateJoinTableDietRestrictionsMenuItems < ActiveRecord::Migration[5.1]
  def change
    create_join_table :diet_restrictions, :menu_items do |t|
      t.index [:diet_restriction_id, :menu_item_id], name: :diet_restriction_id_and_menu_item_id
      # t.index [:menu_item_id, :diet_restriction_id]
    end
  end
end
