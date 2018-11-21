class AddDeactivatedByIdToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :deactivated_by_id, :integer
  end
end
