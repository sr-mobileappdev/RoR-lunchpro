class AddWillSupplyFoodToAppointments < ActiveRecord::Migration[5.1]
  def change
    add_column :appointments, :will_supply_food, :boolean, default: false
  end
end
