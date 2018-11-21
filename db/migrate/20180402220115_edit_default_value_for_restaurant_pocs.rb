class EditDefaultValueForRestaurantPocs < ActiveRecord::Migration[5.1]
  def change
    change_column :restaurant_pocs, :primary, :boolean, :default => false
  end
end
