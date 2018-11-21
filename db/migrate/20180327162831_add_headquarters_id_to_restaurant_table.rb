class AddHeadquartersIdToRestaurantTable < ActiveRecord::Migration[5.1]
  def change
    add_column :restaurants, :headquarters_id, :integer
  end
end
