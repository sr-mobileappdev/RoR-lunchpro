class AddPoliciesLastUpdatedAtToOffices < ActiveRecord::Migration[5.1]
  def change
    add_column :offices, :policies_last_updated_at, :datetime
  end
end
