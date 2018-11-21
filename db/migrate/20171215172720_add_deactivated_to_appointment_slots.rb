class AddDeactivatedToAppointmentSlots < ActiveRecord::Migration[5.1]
  def change
    add_column :appointment_slots, :deactivated_at, :timestamp
    add_column :appointment_slots, :deactivated_by_id, :integer
  end
end
