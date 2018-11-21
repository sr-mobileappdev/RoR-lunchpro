class RemoveExtraneousRepIndexOnDrugsSalesReps < ActiveRecord::Migration[5.1]
  def change
		remove_index :drugs_sales_reps, :sales_rep_id
  end
end
