class AddAppointmentStartsAtToAppointments < ActiveRecord::Migration[5.1]
  def change
    add_column :appointments, :starts_at, :time
  end
end
