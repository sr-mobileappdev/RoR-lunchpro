class AddActivatedToAppointmentSlots < ActiveRecord::Migration[5.1]
  def change
    add_column :appointment_slots, :activated_at, :timestamp
    add_column :appointment_slots, :activated_by_id, :integer
  end
end
