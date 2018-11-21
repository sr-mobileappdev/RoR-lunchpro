class NotificationEventRecipient < ApplicationRecord
  include LunchproRecord
  belongs_to :notification_event
  belongs_to :active_email_template, class_name: 'NotificationTemplate'
  belongs_to :active_sms_template, class_name: 'NotificationTemplate'
  belongs_to :active_push_template, class_name: 'NotificationTemplate'

  def self.recipient_types
    {'Admin' => 'admin', 'Sales Rep' => 'sales_rep', 'Office' => 'office', 'Restaurant' => 'restaurant'}
  end

  # Sweeps through all existing user preferences and resets their default state for ONLY this notification based on current settings.
  # THIS ONLY TAKES ACTION OF THE NEW DEFAULT IS "ON". If new default is off, nothing changes. In other words, we do not UNSET any notifications
  def reset_defaults!(changed_prefs, current_user = nil)
    all_user_prefs = UserNotificationPref.active.all
    all_user_prefs.each do |p|
      p.last_updated_by = current_user if current_user
      if changed_prefs.include?("sms")
        if p.user.user_devices.active.count > 0
          via_push = p.via_push || {}
          via_push["#{self.notification_event_id}"] = 1
          p.via_push = via_push
        else
          via_sms = p.via_sms || {}
          via_sms["#{self.notification_event_id}"] = 1
          p.via_sms = via_sms
        end
      end

      if changed_prefs.include?("email")
        via_email = p.via_email || {}
        via_email["#{self.notification_event_id}"] = 1
        p.via_email = via_email
      end

      p.save
    end
  end

  def notices
    @notices ||= Views::Notices.for_notification_event_recipient(self).all
  end

  def display_recipient_type
    if recipient_type
      recipient_type.humanize
    else
      ""
    end
  end

  def display_priority
    if priority
      case priority
        when 1
          "High"
        when 2
          "Normal"
        when 3
          "Low"
        else
          "Normal"
      end
    else
      "No Priority Set"
    end
  end

  def is_default__flag
    is_email_default || is_sms_default || is_web_default
  end

  def default_summary
    summary = []
    summary << "Email" if is_email_default
    summary << "SMS/Push" if is_sms_default
    summary << "Email" if is_web_default

    (summary.count > 0) ? summary.join(", ") : "No Defaults"
  end



  def self.__columns
    cols = {display_recipient_type: 'Recipient', status__light: 'Status', display_priority: 'Priority', is_default__flag: 'Default?', default_summary: 'Default Enabled'}
    hidden_cols = []
    columns = self.__default_columns.merge(cols).except(*hidden_cols)
  end

end
