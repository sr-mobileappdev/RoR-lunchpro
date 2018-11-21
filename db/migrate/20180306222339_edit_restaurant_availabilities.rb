class EditRestaurantAvailabilities < ActiveRecord::Migration[5.1]
  def change
    change_column :restaurant_availabilities, :starts_at, :time
    change_column :restaurant_availabilities, :ends_at, :time
    rename_column :restaurant_availabilities, :dow, :day_of_week
  end
end
