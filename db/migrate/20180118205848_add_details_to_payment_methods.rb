class AddDetailsToPaymentMethods < ActiveRecord::Migration[5.1]
  def change
    add_column :payment_methods, :cardholder_name, :string
    add_column :payment_methods, :address_line1, :string
    add_column :payment_methods, :address_line2, :string
    add_column :payment_methods, :city, :string
    add_column :payment_methods, :state, :string
    add_column :payment_methods, :postal_code, :string
  end
end
