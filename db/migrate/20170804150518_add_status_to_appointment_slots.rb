class AddStatusToAppointmentSlots < ActiveRecord::Migration[5.1]
  def change
    add_column :appointment_slots, :status, :integer, default: 1
  end
end
