class AddWholesalePercentageToRestaurants < ActiveRecord::Migration[5.1]
  def change
    add_column :restaurants, :wholesale_percentage, :integer, :default => 2000, :null => false
  end
end
