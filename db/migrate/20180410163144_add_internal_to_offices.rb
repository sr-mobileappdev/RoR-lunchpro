class AddInternalToOffices < ActiveRecord::Migration[5.1]
  def change
    add_column :offices, :internal, :boolean, null: false, default: true
  end
end
