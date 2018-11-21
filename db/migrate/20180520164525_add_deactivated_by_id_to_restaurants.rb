class AddDeactivatedByIdToRestaurants < ActiveRecord::Migration[5.1]
  def change
    add_column :restaurants, :deactivated_by_id, :integer
  end
end
