class EditExcludedFlagOfAppointments < ActiveRecord::Migration[5.1]
  def change
    change_column :appointments, :excluded, :bool, :default => false
  end
end
