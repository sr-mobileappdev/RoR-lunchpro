class AddCompanyIndexOnSalesReps < ActiveRecord::Migration[5.1]
  def change
		add_index :sales_reps, :company_id
		add_index :sales_reps, :user_id
  end
end
