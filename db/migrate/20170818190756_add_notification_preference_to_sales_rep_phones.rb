class AddNotificationPreferenceToSalesRepPhones < ActiveRecord::Migration[5.1]
  def change
    add_column :sales_rep_phones, :notification_preference, :integer
  end
end
