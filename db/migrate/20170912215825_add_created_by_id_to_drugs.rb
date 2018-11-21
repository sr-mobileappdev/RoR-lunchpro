class AddCreatedByIdToDrugs < ActiveRecord::Migration[5.1]
  def change
    add_column :drugs, :created_by_id, :integer
  end
end
