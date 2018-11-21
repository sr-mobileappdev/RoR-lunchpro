class AddCreatedByIdToOfficesSalesReps < ActiveRecord::Migration[5.1]
  def change
    add_column :offices_sales_reps, :created_by_id, :integer
  end
end
