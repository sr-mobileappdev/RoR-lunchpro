class AddPublishedAtToMenus < ActiveRecord::Migration[5.1]
  def change
    add_column :menus, :published_at, :datetime
  end
end
