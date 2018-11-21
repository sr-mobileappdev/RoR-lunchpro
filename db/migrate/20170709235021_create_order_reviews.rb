class CreateOrderReviews < ActiveRecord::Migration[5.1]
  def change
    create_table :order_reviews do |t|
      t.references :order
      t.string :title
      t.integer :food_quality
      t.integer :presentation
      t.integer :completion
      t.boolean :on_time
      t.text :comment

      t.timestamps
    end
  end
end
