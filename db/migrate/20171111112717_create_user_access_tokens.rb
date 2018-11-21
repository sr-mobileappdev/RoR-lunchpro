class CreateUserAccessTokens < ActiveRecord::Migration[5.1]
  def change
    create_table :user_access_tokens do |t|
      t.integer :user_id
      t.string :access_token
      t.integer :status, default: 1
      t.string :message
      t.datetime :last_accessed_at
      t.string :last_accessed_ip

      t.timestamps
    end
  end
end
