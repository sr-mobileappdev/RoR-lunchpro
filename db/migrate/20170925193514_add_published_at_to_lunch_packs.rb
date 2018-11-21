class AddPublishedAtToLunchPacks < ActiveRecord::Migration[5.1]
  def change
    add_column :lunch_packs, :published_at, :datetime
    add_column :lunch_packs, :unpublished_at, :datetime
  end
end
