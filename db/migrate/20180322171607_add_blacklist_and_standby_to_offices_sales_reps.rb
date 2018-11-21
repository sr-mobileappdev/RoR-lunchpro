class AddBlacklistAndStandbyToOfficesSalesReps < ActiveRecord::Migration[5.1]
  def change
    add_column :offices_sales_reps, :blacklist, :bool, null: false, default: false
    add_column :offices_sales_reps, :standby, :bool, null: false, default: false
  end
end
