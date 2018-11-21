class AddActivatedAtToSalesRep < ActiveRecord::Migration[5.1]
  def change
    add_column :sales_reps, :activated_at, :datetime
    add_column :sales_reps, :deactivated_at, :datetime
  end
end
