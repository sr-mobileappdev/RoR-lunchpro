class CreateOfficesSalesReps < ActiveRecord::Migration[5.1]
  def change
    create_table :offices_sales_reps do |t|
      t.references :office
      t.references :sales_rep
      t.integer :status

      t.timestamps
    end
  end
end
