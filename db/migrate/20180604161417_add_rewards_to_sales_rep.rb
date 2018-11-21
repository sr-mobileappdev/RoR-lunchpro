class AddRewardsToSalesRep < ActiveRecord::Migration[5.1]
  def change
    add_column :sales_reps, :reward_points, :integer, :default => 0, :null => false
    add_column :sales_reps, :last_reward_date, :datetime
  end
end
