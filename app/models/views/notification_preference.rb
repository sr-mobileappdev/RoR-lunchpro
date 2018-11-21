class Views::NotificationPreference
  attr_reader :email_enabled
  attr_reader :sms_enabled
  attr_reader :notification_event

  def initialize(notification_event, user)
    @notification_event = notification_event
    user_prefs = user.user_notification_prefs.active.where(notifiable_type: nil).first
    @email_enabled = (user_prefs && user_prefs.via_email && user_prefs.via_email["#{notification_event.category_cid}"] && 
      user_prefs.via_email["#{notification_event.category_cid}"] == "1") ? true : false
    @sms_enabled = (user_prefs && user_prefs.via_sms && user_prefs.via_sms["#{notification_event.category_cid}"] && 
      user_prefs.via_sms["#{notification_event.category_cid}"] == "1" ) ? true : false
  end

  def email_enabled?
    @email_enabled
  end

  def sms_enabled?
    @sms_enabled
  end

  def email_enabled__flag
    email_enabled?
  end

  def sms_enabled__flag
    sms_enabled?
  end

  # - The Good Stuff
  def recent_notifications
    @recent_notifications ||= @user.notifications.visible
  end


  def self.__columns
    cols = {sms_enabled__flag: 'SMS Enabled', email_enabled__flag: 'Email Enabled'}
    columns = cols
  end

end
