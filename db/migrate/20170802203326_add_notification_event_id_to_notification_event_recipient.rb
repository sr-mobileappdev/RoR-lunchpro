class AddNotificationEventIdToNotificationEventRecipient < ActiveRecord::Migration[5.1]
  def change
    add_column :notification_event_recipients, :notification_event_id, :integer
  end
end
