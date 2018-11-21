class AddDateToAppointment < ActiveRecord::Migration[5.1]
  def change
    add_column :appointments, :appointment_on, :date
  end
end
