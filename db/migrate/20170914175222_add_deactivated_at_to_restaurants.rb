class AddDeactivatedAtToRestaurants < ActiveRecord::Migration[5.1]
  def change
    add_column :restaurants, :deactivated_at, :datetime
    add_column :restaurants, :activated_at, :datetime
  end
end
