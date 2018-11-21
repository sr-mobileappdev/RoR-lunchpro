class Forms::AdminNotificationEventRecipient < Forms::Form
  attr_writer :params
  attr_reader :errors

  attr_reader :notification_event_recipient
  attr_reader :notification_event

  def initialize(event, params = {}, existing_notification_event_recipient = nil)
    @params = params
    @errors = []

    @notification_event = event
    @notification_event_recipient = existing_notification_event_recipient
  end

  def valid?
    raise "Missing required parameters (:notification_event_recipient)" unless @params[:notification_event_recipient]

    # Validate Sales Rep
    @notification_event_recipient ||= NotificationEventRecipient.new(status: 'active', notification_event_id: @notification_event.id)

    assign_and_archive(@notification_event_recipient, @params[:notification_event_recipient])

    unless @notification_event_recipient.valid?
      @errors += @notification_event_recipient.errors.full_messages
    end

    return (@errors.count == 0)
  end

  def save
    if valid? && persist!
      true
    else
      false
    end
  end

private

  def assign_and_archive(object, params)
    @prior_object ||= object.dup
    object.assign_attributes(@params[:notification_event_recipient])
  end

  def persist!
    ActiveRecord::Base.transaction do

#      return false if !@notification_event_recipient
      # Check for archivable changes
      if @notification_event_recipient.email_content_changed? || @notification_event_recipient.sms_content_changed? || @notification_event_recipient.content_changed?
        @prior_object.assign_attributes(status: "archived", created_at: @notification_event_recipient.created_at) if @prior_object
        @prior_object.save if @prior_object
      end

      if @notification_event_recipient.save
        return true
      else
        raise ActiveRecord::Rollback
      end
    end
    false
  end
end
