class AddCreatedByIdToOfficePocs < ActiveRecord::Migration[5.1]
  def change
    add_column :office_pocs, :created_by_id, :integer
    add_column :office_pocs, :status, :integer, default: 1
  end
end
