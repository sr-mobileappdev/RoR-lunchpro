class AddCreatedByIdToBankAccounts < ActiveRecord::Migration[5.1]
  def change
    add_column :bank_accounts, :created_by_id, :integer
  end
end
