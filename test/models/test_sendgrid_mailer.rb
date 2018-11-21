require 'test_helper'

class TestSendgridMailer < ActiveSupport::TestCase

  def setup
    notification_event = NotificationEvent.create(status: 1, category_cid: '101')
    notification_template = NotificationTemplate.create(template_type: 'email', status: 1, service: 'sendgrid', key: '07b4a0c3-1f9b-4d2c-9ab6-0401d16e2bf8', version: 1)
    recipient = NotificationEventRecipient.create(active_email_template_id: notification_template.id, status: 1, priority: 1, recipient_type: 'admin', notification_event_id: notification_event.id, title: 'Test Email', )

    @notification_email = Notifications::Email.new(notification_event, "admin")
  end

  test "expects a notification email plain object" do
    sm = SendgridMailer.new()
    sm.construct_template(@notification_email, @notification_email.template, {})
    assert sm.can_send?
  end

  test "constructs a sendgrid JSON object" do
    sm = SendgridMailer.new()
    sm.construct_template(@notification_email, @notification_email.template, {})
    response = sm.send!
  end

  test "maintains an errors array" do
    sm = SendgridMailer.new()
    sm.construct_template(@notification_email, @notification_email.template, {})
    response = sm.send!
    assert(response.kind_of?(Hash))
    assert(sm.errors.count == 0)
  end

end
