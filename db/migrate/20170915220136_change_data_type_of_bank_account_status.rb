class ChangeDataTypeOfBankAccountStatus < ActiveRecord::Migration[5.1]
  def change
    remove_column :bank_accounts, :status
    add_column :bank_accounts, :status, :integer, default: 1
  end
end
