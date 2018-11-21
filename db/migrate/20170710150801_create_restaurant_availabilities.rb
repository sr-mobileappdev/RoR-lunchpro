class CreateRestaurantAvailabilities < ActiveRecord::Migration[5.1]
  def change
    create_table :restaurant_availabilities do |t|
      t.references :restaurant
      t.integer :dow
      t.timestamp :starts_at
      t.timestamp :ends_at

      t.timestamps
    end
  end
end
