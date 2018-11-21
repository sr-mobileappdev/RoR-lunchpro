class Notifications::SMS
  attr_reader :notification_event
  attr_reader :notification_recipient
  attr_reader :errors
  attr_reader :to_phone
  attr_reader :overrides
  attr_reader :template
  attr_reader :notification
  attr_reader :message
  attr_reader :http

  def initialize(notification_event, recipient_type, notification, http)
    @errors = []
    @http = http
    @notification = notification
    @notification_event = notification_event
    @notification_recipient = NotificationEventRecipient.active.where(notification_event_id: @notification_event.id, recipient_type: recipient_type).first
    unless @notification_recipient
      @errors << "No active notification recipient set up for this notification event and recipient type."
    end
    if @notification_recipient
      # Assign template
      unless @message = Templates::NotificationTemplate.new(@notification).build(@notification_recipient.sms_content)
        @errors << "No active email template associated with this notification event and recipient type"
      end
    end
  end

  def subject
    @notification_recipient.title || ""
  end
  def notification
    @notification
  end
  def template
    @template
  end

  def message
    @message
  end

  # This may not be the correct place for this function (ie, thing is responsible for trigger the send of itself), but shoudl be fine for now
  def send!(to_phone)
    @to_phone = to_phone
    return false if @errors.count > 0 || !@to_phone.present?
    case preferred_interface
      when :onereach
        deliver_via_onereach!
      else

    end
  end

private

  def preferred_interface
    :onereach
  end

def deliver_via_onereach!
    uri = URI.parse("https://wapi.onereach.com/api/triggermessage/Sms/3yIu96Mw5aagao")
    @message.gsub!("’", "'") #fix for smart quotes
    @message = CGI.unescapeHTML(@message)
    params = {'To' => @to_phone, 'TriggerOrigin' => 'lunchproweb', 'msg' => @message }
      headers = {
        'Content-Type'=>'application/json',
        'apikey'=> ENV["ONEREACH_API_KEY"]
      }
    
    if ENV["STAGING_NOTIFICATIONS"].present? && ENV["STAGING_NOTIFICATIONS"] == "true"
      isProduction = (Rails.env.production?)
      if isProduction
        @to_phone.delete! '()'
        @to_phone.delete! '-'
        @to_phone.delete! ' '
        whiteListNumbers = ['5127451919', '5128011679', '9379039593', '5124615136', '5126992046', '5127616990', '5127451229', '9037449034', '5125606135', '5124363140']

        if whiteListNumbers.include? @to_phone
          response = @http.post(uri.path, params.to_json, headers)
        end
      else
        @to_phone.delete! '()'
        @to_phone.delete! '-'
        @to_phone.delete! ' '
        whiteListNumbers = ['5127451919', '5128011679', '9379039593', '5124615136', '5126992046', '5127616990', '5127451229', '9037449034', '5125606135', '5124363140']

        if whiteListNumbers.include? @to_phone
          response = @http.post(uri.path, params.to_json, headers)
        end
      end
    else
      response = @http.post(uri.path, params.to_json, headers)
    end
  end
end