class AddStripeCustomerToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :stripe_customer, :string
		add_index :users, :stripe_customer
  end
end
