class CreateSalesRepEmails < ActiveRecord::Migration[5.1]
  def change
    create_table :sales_rep_emails do |t|
      t.references :sales_rep
      t.string :email_address
      t.integer :email_type
      t.integer :status
      t.integer :notification_preference

      t.timestamps
    end
  end
end
