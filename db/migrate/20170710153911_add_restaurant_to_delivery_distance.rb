class AddRestaurantToDeliveryDistance < ActiveRecord::Migration[5.1]
  def change
    add_reference :delivery_distances, :restaurant
  end
end
