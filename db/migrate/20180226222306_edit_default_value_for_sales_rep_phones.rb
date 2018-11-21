class EditDefaultValueForSalesRepPhones < ActiveRecord::Migration[5.1]
  def change
    change_column :sales_rep_phones, :phone_type, :integer, :default => 2, :null => false
  end
end
