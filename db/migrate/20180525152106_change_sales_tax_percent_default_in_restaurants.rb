class ChangeSalesTaxPercentDefaultInRestaurants < ActiveRecord::Migration[5.1]
  def change
    change_column :restaurants, :sales_tax_percent, :integer, :default => 825, :null => false
  end
end
