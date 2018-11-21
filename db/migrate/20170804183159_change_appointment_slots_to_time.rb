class ChangeAppointmentSlotsToTime < ActiveRecord::Migration[5.1]
  def change
    change_column :appointment_slots, :starts_at, :time
    change_column :appointment_slots, :ends_at, :time
  end
end
