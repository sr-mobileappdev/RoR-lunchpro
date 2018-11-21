class TwilioSMS
  attr_writer :default_to_phone
  attr_reader :twilio_client
  attr_reader :from_number
  attr_reader :message
  attr_reader :to_number
  attr_reader :errors


  def initialize(default_to_phone = nil)
    @errors = []
    unless Rails.env.production?
      # We are not in production. Send sms to default_to_phone or twilio default
      if default_to_phone
        @default_to_phone = default_to_phone
      else
        @default_to_phone = ENV['TWILIO_DEFAULT_TO']
      end
    end

    account_sid = ENV['TWILIO_ACCOUNT']
    auth_token = ENV['TWILIO_AUTH_TOKEN']

    @client = Twilio::REST::Client.new(account_sid, auth_token)
    @from_number = ENV['TWILIO_DEFAULT_SENDER']
  end

  def construct_template(notify_object, dynamic_vars)

    @message = notify_object.message
    @to_number = notify_object.to_phone
  end

  def can_send?
    if Rails.env.test?
      @errors << "SMS messaging disabled in test environment"
      false
    else
      true
    end
  end

  def from_number
    @from_number
  end

  def message
    @message
  end

  def send!(to_phone = nil)
    phone = @to_number
    if to_phone
      phone = to_phone
    end

    return false unless can_send?

    begin
      @client.api.account.messages.create(
        from: self.from_number,
        to: phone,
        body: self.message
      )

      true
    rescue Exception => e
      @errors << e.message

      puts "\n" * 5
      puts "***" * 30
      puts @errors.inspect
      puts "***" * 30
      puts "\n" * 5

      false
    end

  end

end
