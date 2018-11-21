class AddCreatedByIdToSalesRepPartners < ActiveRecord::Migration[5.1]
  def change
    add_column :sales_rep_partners, :created_by_id, :integer
  end
end
