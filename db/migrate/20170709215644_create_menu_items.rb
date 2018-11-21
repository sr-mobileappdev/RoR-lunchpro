class CreateMenuItems < ActiveRecord::Migration[5.1]
  def change
    create_table :menu_items do |t|
      t.string :name
      t.string :description
      t.string :category
      t.integer :people_served
      t.integer :wholesale_price
      t.integer :retail_price
      t.references :modified_by_user
      t.integer :status
      t.bigint :ordered_counter

      t.timestamps
    end
  end
end
