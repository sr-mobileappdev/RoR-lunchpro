class AddCreatedByIdToOfficesProviders < ActiveRecord::Migration[5.1]
  def change
    add_column :offices_providers, :created_by_id, :integer
  end
end
