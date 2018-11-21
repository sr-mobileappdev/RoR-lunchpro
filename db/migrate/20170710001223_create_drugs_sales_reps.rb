class CreateDrugsSalesReps < ActiveRecord::Migration[5.1]
  def change
    create_table :drugs_sales_reps do |t|
      t.references :sales_rep
      t.references :drug
      t.integer :status

      t.timestamps
			t.index [:sales_rep_id, :drug_id]
    end
  end
end
