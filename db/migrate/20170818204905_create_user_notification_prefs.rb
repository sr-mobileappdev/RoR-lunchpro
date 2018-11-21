class CreateUserNotificationPrefs < ActiveRecord::Migration[5.1]
  def change
    create_table :user_notification_prefs do |t|
      t.integer :user_id
      t.integer :status, default: 1
      t.string :notifiable_type
      t.integer :notifiable_id
      t.jsonb :via_email
      t.jsonb :via_sms
      t.jsonb :via_push
      t.integer :last_updated_by_id

      t.timestamps
    end
  end
end
