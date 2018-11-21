class RemoveLineItemMenuId < ActiveRecord::Migration[5.1]
  def change
    remove_column :line_items, :menu_id
  end
end
