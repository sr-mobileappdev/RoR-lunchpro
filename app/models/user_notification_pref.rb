class UserNotificationPref < ApplicationRecord
  include LunchproRecord

  belongs_to :user
  belongs_to :notifiable, polymorphic: true
  belongs_to :last_updated_by, class_name: 'User'

  def reset_to_default!(updating_user = nil)

    self.last_updated_by = updating_user
    self.via_email = {}
    self.via_sms = {}
    self.via_push = {}

    sms_recipients = NotificationEventRecipient.where(recipient_type: user_notification_type, is_sms_default: true)
    if user.user_devices.active.count > 0
      # User has active push devices on file, use push defaults instead of SMS
      sms_recipients.each do |r|
        self.via_push["#{r.notification_event_id}"] = 1
      end
    else
      # No push devices, assign SMS defaults
      sms_recipients.each do |r|
        self.via_sms["#{r.notification_event_id}"] = 1
      end
    end

    # Assign email defaults
    recipients = NotificationEventRecipient.where(recipient_type: user_notification_type, is_email_default: true)
    recipients.each do |r|
      self.via_email["#{r.notification_event_id}"] = 1
    end

    self.save

  end
  
  def notification_event_ids_for_email
  	if via_email.present?
  		return via_email.select { |key, value| value == "1" }.keys  	
  	else
		return []
	end
  end
  
  def notification_event_ids_for_sms
  	if via_sms.present?
  		return via_sms.select { |key, value| value == "1" }.keys  	
  	else
		return []
	end
  end

  def via_sms=(prefs)    
    return if !user || !user.space
    if user.space == "space_sales_rep"
      write_attribute(:via_sms, prefs.merge(User.standard_rep_notifications(false)))
    elsif user.space == "space_restaurant"
      write_attribute(:via_sms, prefs.merge(User.standard_restaurant_notifications(false)))
    end
  end

  def via_email=(prefs)
    return if !user || !user.space
    if user.space == "space_sales_rep"
      write_attribute(:via_email, prefs.merge(User.standard_rep_notifications(true)))
    elsif user.space == "space_office"
      write_attribute(:via_email, prefs.merge(User.standard_office_notifications(true)))
    elsif user.space == "space_restaurant"
      write_attribute(:via_email, prefs.merge(User.standard_restaurant_notifications(true)))
    end
  end

  def user_notification_type
    if user
      if user.space_admin?
        "admin"
      elsif user.space_sales_rep?
        "sales_rep"
      elsif user.space_office?
        "office"
      elsif user.space_restaurant?
        "restaurant"
      else
        nil
      end
    else
      nil
    end
  end

end
