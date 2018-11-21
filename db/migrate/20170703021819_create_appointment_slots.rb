class CreateAppointmentSlots < ActiveRecord::Migration[5.1]
  def change
    create_table :appointment_slots do |t|
      t.string :name
      t.integer :day_of_week
      t.timestamp :starts_at
      t.timestamp :ends_at
      t.integer :staff_count

      t.timestamps
    end
  end
end
