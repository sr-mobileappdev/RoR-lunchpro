class AddActiveEmailTemplateIdToNotificationEventRecipient < ActiveRecord::Migration[5.1]
  def change
    add_column :notification_event_recipients, :active_email_template_id, :integer
    add_column :notification_event_recipients, :active_sms_template_id, :integer
    add_column :notification_event_recipients, :active_push_template_id, :integer
  end
end
