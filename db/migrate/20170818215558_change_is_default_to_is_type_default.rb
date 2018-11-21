class ChangeIsDefaultToIsTypeDefault < ActiveRecord::Migration[5.1]
  def change
    rename_column :notification_event_recipients, :is_default, :is_email_default
    add_column :notification_event_recipients, :is_sms_default, :boolean, default: false
    add_column :notification_event_recipients, :is_web_default, :boolean, default: false
  end
end
