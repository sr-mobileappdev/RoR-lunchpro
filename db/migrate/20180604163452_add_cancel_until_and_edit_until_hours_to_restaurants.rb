class AddCancelUntilAndEditUntilHoursToRestaurants < ActiveRecord::Migration[5.1]
  def change
    add_column :restaurants, :cancel_until_hours, :integer, :default => 24, :null => false
    add_column :restaurants, :edit_until_hours, :integer,  :default => 6, :null => false
  end
end
