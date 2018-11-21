class AddOfficeNotesToOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :office_notes, :string
  end
end
