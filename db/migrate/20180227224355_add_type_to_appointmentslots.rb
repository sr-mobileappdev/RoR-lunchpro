class AddTypeToAppointmentslots < ActiveRecord::Migration[5.1]
  def change
    add_column :appointment_slots, :type, :integer
  end
end
