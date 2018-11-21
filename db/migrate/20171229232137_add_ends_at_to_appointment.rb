class AddEndsAtToAppointment < ActiveRecord::Migration[5.1]
  def change
    add_column :appointments, :ends_at, :timestamp
  end
end
