class ChangeEndsAtForAppointment < ActiveRecord::Migration[5.1]
  def change
    change_column :appointments, :ends_at, :time
  end
end
