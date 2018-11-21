class CreateUserDevices < ActiveRecord::Migration[5.1]
  def change
    create_table :user_devices do |t|
      t.integer :user_id
      t.integer :status, default: 1
      t.string :token
      t.string :arn
      t.datetime :last_used_at

      t.timestamps
    end
  end
end
