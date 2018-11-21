class ChangeSalesTaxPercentInRestaurants < ActiveRecord::Migration[5.1]
  def change
    change_column :restaurants, :sales_tax_percent, :integer, :default => 8250, :null => false
  end
end
