class AddPriceRangesToRestaurants < ActiveRecord::Migration[5.1]
  def change
    add_column :restaurants, :person_price_low, :integer
    add_column :restaurants, :person_price_high, :integer
  end
end
