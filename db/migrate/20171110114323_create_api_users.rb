class CreateApiUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :api_users do |t|
      t.string :name
      t.string :api_key
      t.boolean :is_enabled, default: false
      t.integer :enabled_by_user_id
      t.datetime :disabled_at
      t.integer :disabled_by_user_id

      t.timestamps
    end
  end
end
