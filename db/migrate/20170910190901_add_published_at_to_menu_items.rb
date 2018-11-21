class AddPublishedAtToMenuItems < ActiveRecord::Migration[5.1]
  def change
    add_column :menu_items, :published_at, :datetime
  end
end
