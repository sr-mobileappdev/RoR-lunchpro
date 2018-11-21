class ChangeStatusToIntForRestaurantAvailabilitiesv2 < ActiveRecord::Migration[5.1]
  def change    
    change_column :restaurant_availabilities, :status, 'integer USING CAST(status AS integer)'
  end
end
