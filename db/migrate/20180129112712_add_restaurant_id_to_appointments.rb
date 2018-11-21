class AddRestaurantIdToAppointments < ActiveRecord::Migration[5.1]
  def change
    add_column :appointments, :restaurant_id, :integer
  end
end
