class CreateNotificationEventRecipients < ActiveRecord::Migration[5.1]
  def change
    create_table :notification_event_recipients do |t|
      t.string :recipient_type
      t.integer :status, default: 1
      t.string :title
      t.integer :priority, default: 2
      t.integer :activated_by_user
      t.datetime :activated_at
      t.integer :deactivated_by_user
      t.datetime :deactivated_at

      t.timestamps
    end
  end
end
