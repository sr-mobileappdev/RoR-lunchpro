class AddOfficeToAppointmentSlots < ActiveRecord::Migration[5.1]
  def change
    add_column :appointment_slots, :office_id, :integer
  end
end
