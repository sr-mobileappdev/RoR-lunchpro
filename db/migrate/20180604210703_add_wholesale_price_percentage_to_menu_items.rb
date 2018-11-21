class AddWholesalePricePercentageToMenuItems < ActiveRecord::Migration[5.1]
  def change
    add_column :menu_items, :wholesale_price_percentage, :integer
  end
end
