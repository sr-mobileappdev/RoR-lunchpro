class CreateDeliveryDistances < ActiveRecord::Migration[5.1]
  def change
    create_table :delivery_distances do |t|
      t.integer :radius
      t.boolean :use_complex
      t.integer :north
      t.integer :north_east
      t.integer :east
      t.integer :south_east
      t.integer :south
      t.integer :south_west
      t.integer :west
      t.integer :north_west

      t.timestamps
    end
  end
end
