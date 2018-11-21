class EditTypeOfAppointmentSlots < ActiveRecord::Migration[5.1]
  def change
    rename_column :appointment_slots, :type, :slot_type
  end
end
