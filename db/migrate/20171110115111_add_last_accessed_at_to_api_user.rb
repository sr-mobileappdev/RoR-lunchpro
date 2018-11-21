class AddLastAccessedAtToApiUser < ActiveRecord::Migration[5.1]
  def change
    add_column :api_users, :last_accessed_at, :datetime
  end
end
