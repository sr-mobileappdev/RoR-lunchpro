class ChangeAccountTypeToEnum < ActiveRecord::Migration[5.1]
  def change
    remove_column :bank_accounts, :account_type
    add_column :bank_accounts, :account_type, :integer
  end
end
