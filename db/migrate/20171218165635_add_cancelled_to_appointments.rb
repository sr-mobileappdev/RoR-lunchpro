class AddCancelledToAppointments < ActiveRecord::Migration[5.1]
  def change
    add_column :appointments, :cancelled_at, :timestamp
    add_column :appointments, :cancelled_by_id, :integer
    add_column :appointments, :cancel_reason, :string
  end
end
