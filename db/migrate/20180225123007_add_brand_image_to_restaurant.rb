class AddBrandImageToRestaurant < ActiveRecord::Migration[5.1]
  def change
    add_column :restaurants, :brand_image, :string
  end
end
