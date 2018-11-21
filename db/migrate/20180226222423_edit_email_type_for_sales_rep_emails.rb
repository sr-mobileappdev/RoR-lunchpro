class EditEmailTypeForSalesRepEmails < ActiveRecord::Migration[5.1]
  def change
    change_column :sales_rep_emails, :email_type, :integer, :default => 2, :null => false
  end
end
