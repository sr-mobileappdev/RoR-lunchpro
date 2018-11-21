class AddAppointmentTypeToAppointments < ActiveRecord::Migration[5.1]
  def change
    add_column :appointments, :appointment_type, :integer, null: false, default: 1
    add_index :appointments, :appointment_type
  end
end
