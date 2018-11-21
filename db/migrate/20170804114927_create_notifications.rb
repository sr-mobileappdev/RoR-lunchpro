class CreateNotifications < ActiveRecord::Migration[5.1]
  def change
    create_table :notifications do |t|
      t.integer :user_id
      t.integer :status, default: 1
      t.string :title
      t.integer :notification_event_id
      t.string :relatable_type
      t.integer :relatable_id
      t.integer :priority
      t.datetime :read_at
      t.datetime :removed_at

      t.timestamps
    end
  end
end
