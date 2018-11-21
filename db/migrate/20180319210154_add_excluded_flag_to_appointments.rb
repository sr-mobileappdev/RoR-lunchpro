class AddExcludedFlagToAppointments < ActiveRecord::Migration[5.1]
  def change
    add_column :appointments, :excluded, :bool
  end
end
