class AddTitleToAppointments < ActiveRecord::Migration[5.1]
  def change
    add_column :appointments, :title, :string
  end
end
