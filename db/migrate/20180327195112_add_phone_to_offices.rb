class AddPhoneToOffices < ActiveRecord::Migration[5.1]
  def change
    add_column :offices, :phone, :text
  end
end
