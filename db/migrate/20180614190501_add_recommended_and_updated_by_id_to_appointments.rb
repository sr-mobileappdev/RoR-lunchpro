class AddRecommendedAndUpdatedByIdToAppointments < ActiveRecord::Migration[5.1]
  def change
    add_column :appointments, :recommended_by_id, :integer
    add_column :appointments, :updated_by_id, :integer
  end
end
