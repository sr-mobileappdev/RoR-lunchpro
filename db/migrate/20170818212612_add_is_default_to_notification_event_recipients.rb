class AddIsDefaultToNotificationEventRecipients < ActiveRecord::Migration[5.1]
  def change
    add_column :notification_event_recipients, :is_default, :boolean, default: false
  end
end
