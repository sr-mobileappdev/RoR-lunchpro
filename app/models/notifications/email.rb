class Notifications::Email
  attr_writer :notification_event
  attr_writer :notification_recipient
  attr_writer :errors
  attr_reader :to_addresses
  attr_writer :overrides
  attr_writer :template

  def initialize(notification_event, recipient_type)
    @errors = []

    @notification_event = notification_event
    @notification_recipient = NotificationEventRecipient.active.where(notification_event_id: @notification_event.id, recipient_type: recipient_type).first
    unless @notification_recipient
      @errors << "No active notification recipient set up for this notification event and recipient type."
    end

    # Assign template
    unless @template = @notification_recipient.active_email_template
      @errors << "No active email template associated with this notification event and recipient type"
    end

  end

  def subject
    @notification_recipient.title || "No Subject"
  end

  def template
    @template
  end

  # This may not be the correct place for this function (ie, thing is responsible for trigger the send of itself), but shoudl be fine for now
  def send!(to_addresses = [])
    @to_addresses = to_addresses
    return false if @errors.count > 0
    case preferred_interface
      when :sendgrid
        deliver_via_sendgrid!
      else

    end
  end

private

  def preferred_interface
    :sendgrid
  end

  def deliver_via_sendgrid!
    mailer = SendgridMailer.new()
    mailer.construct_template(self, @template, {})
    mailer.send!
  end


end
