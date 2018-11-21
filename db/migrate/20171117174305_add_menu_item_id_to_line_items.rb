class AddMenuItemIdToLineItems < ActiveRecord::Migration[5.1]
  def change
    add_column :line_items, :orderable_id, :integer
    add_column :line_items, :orderable_type, :string
    add_column :line_items, :parent_line_item_id, :integer
  end
end
