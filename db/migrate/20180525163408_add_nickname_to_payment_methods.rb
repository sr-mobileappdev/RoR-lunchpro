class AddNicknameToPaymentMethods < ActiveRecord::Migration[5.1]
  def change
    add_column :payment_methods, :nickname, :string
  end
end
