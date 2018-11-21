class AddLateCancellationFeeToRestaurants < ActiveRecord::Migration[5.1]
  def change
    add_column :restaurants, :late_cancel_fee_cents, :integer
  end
end
