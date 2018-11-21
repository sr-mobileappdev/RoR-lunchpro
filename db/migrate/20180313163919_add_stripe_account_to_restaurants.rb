class AddStripeAccountToRestaurants < ActiveRecord::Migration[5.1]
  def change
    add_column :restaurants, :stripe_account, :string
    add_index :restaurants, :stripe_account
  end
end
