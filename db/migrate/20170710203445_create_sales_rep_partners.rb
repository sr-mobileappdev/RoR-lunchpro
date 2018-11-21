class CreateSalesRepPartners < ActiveRecord::Migration[5.1]
  def change
    create_table :sales_rep_partners do |t|
      t.references :sales_rep
      t.integer :partner_id
      t.integer :status

      t.timestamps
    end
    add_index :sales_rep_partners, :partner_id
  end
end
