class AddSpecialtiesToSalesReps < ActiveRecord::Migration[5.1]
  def change    
    add_column :sales_reps, :specialties, :text, array: true, default: []
  end
end
