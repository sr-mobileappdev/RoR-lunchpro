class RenamePaymentToPaymentMethod < ActiveRecord::Migration[5.1]
  def change
  	rename_table :payments, :payment_methods
  end
end
