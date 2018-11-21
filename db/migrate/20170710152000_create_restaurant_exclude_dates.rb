class CreateRestaurantExcludeDates < ActiveRecord::Migration[5.1]
  def change
    create_table :restaurant_exclude_dates do |t|
      t.references :restaurant
      t.timestamp :starts_at
      t.timestamp :ends_at

      t.timestamps
    end
  end
end
