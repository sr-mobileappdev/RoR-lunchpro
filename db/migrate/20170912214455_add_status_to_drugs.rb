class AddStatusToDrugs < ActiveRecord::Migration[5.1]
  def change
    add_column :drugs, :status, :integer, default: 1
  end
end
