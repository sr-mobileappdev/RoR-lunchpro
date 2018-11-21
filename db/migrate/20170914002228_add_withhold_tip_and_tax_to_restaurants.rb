class AddWithholdTipAndTaxToRestaurants < ActiveRecord::Migration[5.1]
  def change
    add_column :restaurants, :withhold_tip, :boolean, default: false, null: false
    add_column :restaurants, :withhold_tax, :boolean, default: false, null: false
  end
end
