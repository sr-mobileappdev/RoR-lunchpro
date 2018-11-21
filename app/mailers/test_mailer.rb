class TestMailer < ApplicationMailer
  default from: 'admin@lunchpro.com'
  layout 'mailer'

  def general_test
    sparkpost_config = {
      track_opens: true,
      track_clicks: false,
      campaign_id: "Test Campaign",
      transactional: true,
    }


    mail(to: 'josh@brightcraftmobile.com', from: "Admin <admin@lunchpro.com>", subject: 'Test Email Delivery')
  end
end
