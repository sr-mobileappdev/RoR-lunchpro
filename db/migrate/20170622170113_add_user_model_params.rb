class AddUserModelParams < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :primary_phone, :string
    add_column :users, :space, :integer, default: 1
    add_column :users, :status, :integer, default: 1
    add_column :users, :validated_at, :datetime
    add_column :users, :validated_by_id, :integer
    add_column :users, :last_modified_at, :datetime
    add_column :users, :last_modified_by_id, :integer

  end
end
