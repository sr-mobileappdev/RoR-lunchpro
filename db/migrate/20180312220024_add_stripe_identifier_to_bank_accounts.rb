class AddStripeIdentifierToBankAccounts < ActiveRecord::Migration[5.1]
  def change
    add_column :bank_accounts, :stripe_identifier, :string
  end
end
