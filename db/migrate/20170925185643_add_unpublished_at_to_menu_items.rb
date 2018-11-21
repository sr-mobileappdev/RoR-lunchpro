class AddUnpublishedAtToMenuItems < ActiveRecord::Migration[5.1]
  def change
    add_column :menu_items, :unpublished_at, :datetime
  end
end
