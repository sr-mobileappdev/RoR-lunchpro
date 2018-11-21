class AddStatusToRestaurantAvailabilities < ActiveRecord::Migration[5.1]
  def change
    add_column :restaurant_availabilities, :status, :string, default: "inactive"
  end
end
