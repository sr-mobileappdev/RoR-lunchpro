class SetDefaultValueOfOriginToAppointments < ActiveRecord::Migration[5.1]
  def change
    change_column :appointments, :origin, :integer, :default => 3, :null => false
  end
end
