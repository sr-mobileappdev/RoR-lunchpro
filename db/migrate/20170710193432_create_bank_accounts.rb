class CreateBankAccounts < ActiveRecord::Migration[5.1]
  def change
    create_table :bank_accounts do |t|
      t.references :restaurant
      t.string :bank_name
      t.string :routing_number
      t.string :account_number
      t.string :account_type
      t.string :address_line1
      t.string :address_line2
      t.string :city
      t.string :state
      t.string :postal
      t.string :phone_number
      t.string :status

      t.timestamps
    end
  end
end
