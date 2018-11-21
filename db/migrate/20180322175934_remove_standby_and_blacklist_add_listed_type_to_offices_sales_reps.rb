class RemoveStandbyAndBlacklistAddListedTypeToOfficesSalesReps < ActiveRecord::Migration[5.1]
  def change
    remove_column :offices_sales_reps, :blacklist
    remove_column :offices_sales_reps, :standby
    add_column :offices_sales_reps, :listed_type, :integer, null: false, default: 0
  end
end
