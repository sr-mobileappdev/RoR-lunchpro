class AddSalesTaxPercentToRestaurants < ActiveRecord::Migration[5.1]
  def change
    add_column :restaurants, :sales_tax_percent, :integer
  end
end
