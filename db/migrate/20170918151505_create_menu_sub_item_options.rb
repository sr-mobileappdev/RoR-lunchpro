class CreateMenuSubItemOptions < ActiveRecord::Migration[5.1]
  def change
    create_table :menu_sub_item_options do |t|
      t.integer :menu_sub_item_id
      t.string :option_name
      t.integer :price_cents, default: 0
      t.integer :status, default: 1

      t.timestamps
    end
  end
end
