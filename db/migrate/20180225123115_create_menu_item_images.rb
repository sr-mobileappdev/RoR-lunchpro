class CreateMenuItemImages < ActiveRecord::Migration[5.1]
  def change
    create_table :menu_item_images do |t|
      t.string :image
      t.integer :status, default: 1
      t.integer :position
      t.text :caption

      t.timestamps
    end
  end
end
