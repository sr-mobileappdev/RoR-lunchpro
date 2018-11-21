class AddProcessingFeeToRestaurants < ActiveRecord::Migration[5.1]
  def change
    add_column :restaurants, :processing_fee_percent, :integer
  end
end
