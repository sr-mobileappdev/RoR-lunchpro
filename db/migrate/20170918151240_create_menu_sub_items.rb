class CreateMenuSubItems < ActiveRecord::Migration[5.1]
  def change
    create_table :menu_sub_items do |t|
      t.integer :menu_item_id
      t.string :name
      t.text :description
      t.integer :qty_allowed, default: 1
      t.integer :base_price_cents, default: 0
      t.integer :status, default: 1

      t.timestamps
    end
  end
end
