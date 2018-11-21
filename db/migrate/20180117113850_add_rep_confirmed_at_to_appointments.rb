class AddRepConfirmedAtToAppointments < ActiveRecord::Migration[5.1]
  def change
    add_column :appointments, :rep_confirmed_at, :datetime
    add_column :appointments, :office_confirmed_at, :datetime
    add_column :appointments, :restaurant_confirmed_at, :datetime
    remove_column :appointments, :rep_confirmed
    remove_column :appointments, :office_confirmed
    remove_column :appointments, :restaurant_confirmed
  end
end
