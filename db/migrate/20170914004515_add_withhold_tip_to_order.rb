class AddWithholdTipToOrder < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :withhold_tip, :boolean, default: false, null: false
  end
end
