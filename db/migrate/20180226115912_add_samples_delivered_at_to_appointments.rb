class AddSamplesDeliveredAtToAppointments < ActiveRecord::Migration[5.1]
  def change
    add_column :appointments, :samples_delivered_at, :datetime
    add_column :appointments, :samples_requested, :text, array: true, default: []
  end
end
