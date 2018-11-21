class AddDeactivatedToCompanies < ActiveRecord::Migration[5.1]
  def change
    add_column :companies, :deactivated_at, :timestamp
    add_column :companies, :deactivated_by_id, :integer
  end
end
