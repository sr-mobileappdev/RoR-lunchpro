class AddPrimaryToRestaurantPocs < ActiveRecord::Migration[5.1]
  def change
    add_column :restaurant_pocs, :primary, :bool
  end
end
