class CreateLineItems < ActiveRecord::Migration[5.1]
  def change
    create_table :line_items do |t|
      t.references :order
      t.references :menu
      t.string :name
      t.integer :quantity
      t.integer :cost
      t.text :notes

      t.timestamps
    end
  end
end
