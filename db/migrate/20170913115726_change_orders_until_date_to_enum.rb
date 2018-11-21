class ChangeOrdersUntilDateToEnum < ActiveRecord::Migration[5.1]
  def change
    remove_column :restaurants, :orders_until_date
    add_column :restaurants, :orders_until, :integer
  end
end
