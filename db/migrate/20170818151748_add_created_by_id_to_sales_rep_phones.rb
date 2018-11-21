class AddCreatedByIdToSalesRepPhones < ActiveRecord::Migration[5.1]
  def change
    add_column :sales_rep_phones, :created_by_id, :integer
    add_column :sales_rep_emails, :created_by_id, :integer
  end
end
