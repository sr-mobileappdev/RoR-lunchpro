class EditPhoneForOffices < ActiveRecord::Migration[5.1]
  def change
    change_column :offices, :phone, :string
  end
end
