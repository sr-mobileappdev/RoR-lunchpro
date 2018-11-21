class AddOriginToAppointments < ActiveRecord::Migration[5.1]
  def change
    add_column :appointments, :origin, :integer
  end
end
