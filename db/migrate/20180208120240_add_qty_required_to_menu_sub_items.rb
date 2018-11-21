class AddQtyRequiredToMenuSubItems < ActiveRecord::Migration[5.1]
  def change
    add_column :menu_sub_items, :qty_required, :integer, default: 0
  end
end
