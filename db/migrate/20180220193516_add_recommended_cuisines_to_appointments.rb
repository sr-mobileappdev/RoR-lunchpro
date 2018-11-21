class AddRecommendedCuisinesToAppointments < ActiveRecord::Migration[5.1]
  def change
    add_column :appointments, :recommended_cuisines, :integer, array: true,  default: '{}'
  end
end
