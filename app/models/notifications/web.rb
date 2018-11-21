class Notifications::Web
  attr_writer :notification_event
  attr_writer :notification_recipient
  attr_writer :errors
  attr_writer :overrides
  attr_writer :template

  def initialize(notification, notification_event, recipient_type)
    @errors = []

    @notification_event = notification_event
    @notification_recipient = NotificationEventRecipient.active.where(notification_event_id: @notification_event.id, recipient_type: recipient_type).first
    unless @notification_recipient
      @errors << "No active notification recipient set up for this notification event and recipient type."
    end

    if @notification_recipient
      @template = Templates::NotificationWebTemplate.new(notification)
    end

  end

  def title
    (@template) ? @template.build(@notification_recipient.content).html_safe : ''
  end



private



end
