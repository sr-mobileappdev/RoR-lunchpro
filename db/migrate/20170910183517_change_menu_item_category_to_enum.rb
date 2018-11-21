class ChangeMenuItemCategoryToEnum < ActiveRecord::Migration[5.1]
  def change
    remove_column :menu_items, :category
    add_column :menu_items, :category, :integer
  end
end
