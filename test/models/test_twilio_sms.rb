require 'test_helper'

class TestTwilioSMS < ActiveSupport::TestCase

  def setup
    notification_event = NotificationEvent.create(status: 1, category_cid: '101')
    notification_template = NotificationTemplate.create(template_type: 'sms', status: 1, service: 'twilio', version: 1)
    recipient = NotificationEventRecipient.create(active_sms_template_id: notification_template.id, status: 1, priority: 1, recipient_type: 'admin', notification_event_id: notification_event.id, title: 'Test SMS', )

    @notification_sms = Notifications::SMS.new(notification_event, "admin")
  end

  test "expects a notification email plain object" do
    sm = TwilioSMS.new()
    sm.construct_template(@notification_sms, {})
  end

  test "constructs a twilio delivery object" do
    sm = TwilioSMS.new()
    sm.construct_template(@notification_sms, {})
    response = sm.send!("+12143640193")
  end

  test "maintains an errors array" do
    sm = TwilioSMS.new()

    sm.construct_template(@notification_sms, {})
    response = sm.send!("+12143640193")
    if response
      assert(response.kind_of?(Hash))
    else
      assert(sm.errors.count > 0)
    end
  end

end
