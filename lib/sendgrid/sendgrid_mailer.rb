class SendgridMailer
  attr_writer :template_id
  attr_writer :to_email
  attr_writer :dynamic_vars
  attr_writer :sendgrid_data
  attr_writer :default_to_address
  attr_writer :errors

  def initialize(default_to_address = nil)
    @sendgrid_data = {}
    @errors = []
    unless Rails.env.production?
      # We are not in production. Send emails to default_to_address or sendgrid default
      if default_to_address
        @default_to_address = default_to_address
      else
        @default_to_address = ENV['SENDGRID_DEFAULT_TO']
      end
    end
  end

  def construct_template(notify_object, template, dynamic_vars)
    unless notify_object && notify_object.kind_of?(Notifications::Email)
      raise "Attempting to send email without providing a Notifications::Email object"
    end

    subject = notify_object.subject

    destination_emails = []

    # Don't send emails to random folks from development
    if production?
      notify_object.to_addresses.each do |t|
        destination_emails << {"email" => t}
      end
    else
      destination_emails << {"email" => @default_to_address}
    end

    sd = @sendgrid_data

    sd["personalizations"] = []
    sd["personalizations"] << {"to" => destination_emails, "subject" => subject }

    sd["from"] = {"email" => "admin@lunchpro.com"}

    sd["template_id"] = notify_object.template.key

    @sendgrid_data = sd
  end

  def can_send?
    (@sendgrid_data && ENV['SENDGRID_KEY'] && @sendgrid_data["personalizations"].count > 0)
  end

  def send!
    raise "No template constructed" unless @sendgrid_data

    sg = SendGrid::API.new(api_key: ENV['SENDGRID_KEY'])

    if Rails.env.test?
      # Don't deliver emails in test environment
      return @sendgrid_data
    else
      response = sg.client.mail._("send").post(request_body: @sendgrid_data)
    end
  end

  def errors
    @errors
  end


  def production?
    Rails.env.production?
  end

end
