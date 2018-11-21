class AddActivatedAtToOffices < ActiveRecord::Migration[5.1]
  def change
    add_column :offices, :activated_at, :datetime
    add_column :offices, :activated_by_id, :integer
    add_column :offices, :deactivated_at, :datetime
    add_column :offices, :deactivated_by_id, :integer
  end
end
