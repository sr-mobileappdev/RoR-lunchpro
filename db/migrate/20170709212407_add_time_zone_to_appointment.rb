class AddTimeZoneToAppointment < ActiveRecord::Migration[5.1]
  def change
    add_column :appointments, :time_zone, :string
  end
end
