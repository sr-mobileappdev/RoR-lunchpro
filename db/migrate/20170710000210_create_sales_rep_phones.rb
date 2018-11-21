class CreateSalesRepPhones < ActiveRecord::Migration[5.1]
  def change
    create_table :sales_rep_phones do |t|
      t.references :sales_rep
      t.string :phone_number
      t.integer :phone_type
      t.integer :status

      t.timestamps
    end
  end
end
