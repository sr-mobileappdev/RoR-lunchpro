class AddContentToRecipients < ActiveRecord::Migration[5.1]
  def change
    add_column :notification_event_recipients, :content, :text
    add_column :notification_event_recipients, :sms_content, :text
    add_column :notification_event_recipients, :email_content, :text
  end
end
