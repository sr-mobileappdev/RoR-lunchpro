class RenameSpecialtyOnProviders < ActiveRecord::Migration[5.1]
  def change
    remove_column :providers, :specialty # delete and add
    add_column :providers, :specialties, :text, array: true, default: []
  end
end
