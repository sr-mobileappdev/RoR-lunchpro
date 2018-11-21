class AddStatusToPayments < ActiveRecord::Migration[5.1]
  def change
    add_column :payments, :status, :integer, default: 1
		add_index :payments, :status
  end
end
