class RenamePaymentsExpiresOn < ActiveRecord::Migration[5.1]
  def change
		remove_column :payments, :expires_on # delete an add because existing values are a B to convert to valid integers
		add_column :payments, :expire_month, :integer
		add_column :payments, :expire_year, :integer
  end
end
