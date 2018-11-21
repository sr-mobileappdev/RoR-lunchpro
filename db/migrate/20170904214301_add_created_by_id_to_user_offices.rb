class AddCreatedByIdToUserOffices < ActiveRecord::Migration[5.1]
  def change
    add_column :user_offices, :created_by_id, :integer
  end
end
