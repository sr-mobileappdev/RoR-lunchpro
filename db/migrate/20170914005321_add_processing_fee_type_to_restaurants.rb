class AddProcessingFeeTypeToRestaurants < ActiveRecord::Migration[5.1]
  def change
    add_column :restaurants, :processing_fee_type, :integer, default: 10
  end
end
