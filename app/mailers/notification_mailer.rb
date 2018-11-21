class NotificationMailer < SparkpostMailer
  default from: 'LunchPro <admin@lunchpro.com>'
  layout 'notification_mailer'

  def notification(notification, processed_by = nil)
    @from_address = ENV['SPARKPOST_DEFAULT_FROM']
    to_email = (Rails.env.production?) ? notification.to_email : processed_by.email
    if ENV["STAGING_NOTIFICATIONS"].present? && ENV["STAGING_NOTIFICATIONS"] == "true"
      if (to_email.include? 'collectivepoint.com') || to_email == 'michael.q.carr@gmail.com'
        
      else
        return
      end
    end
    return unless to_email
    if notification.related_objects["restaurant_poc"]
      set_content(notification, notification.notification_event.notification_event_recipients.where(:recipient_type => "restaurant").first)
    elsif notification.related_objects["non_lp_sales_rep_id"].present?
      set_content(notification, notification.notification_event.notification_event_recipients.where(:recipient_type => "sales_rep").first)
    else
      set_content(notification)
    end
    send_via_sparkpost(to_email, @recipient.title, 'notification', notification)
  end

  def simulate_notification(recipient, admin_user, to_email)

    @from_address = ENV['SPARKPOST_DEFAULT_FROM']

    # Faux notification object for simulated notification
    notification = Notification.new(user: admin_user,
                                    title: recipient.title,
                                    notification_event_id: recipient.notification_event_id,
                                    priority: 1,
                                    related_objects: {} )

    simulated_objects(notification, recipient)

    set_content(notification, recipient)
    send_via_sparkpost(to_email, recipient.title, 'notification')
  end

private

  def simulated_objects(notification, recipient)
    notification.sim_office = Office.new(name: 'Doctors & Associates')
    notification.sim_sales_rep = SalesRep.new(first_name: 'John', last_name: 'Doe', company: Company.new(name: 'Medical Supply Ltd.'))
    notification.sim_appointment = Appointment.new( appointment_slot: AppointmentSlot.new(name: 'Breakfast', day_of_week: 1, starts_at: '08:30:00', ends_at: '09:30:00', staff_count: 3),
                                                    appointment_on: Time.now.to_date.next_week.beginning_of_week,
                                                    starts_at: '08:30:00',
                                                    office: notification.sim_office,
                                                    sales_rep: notification.sim_sales_rep)
  end

  def set_content(notification, recipient = nil)

    if recipient
      @recipient = recipient
    else
      user = notification.user
      event = notification.notification_event

      @recipient = event.notification_event_recipients.where(recipient_type: user.notification_recipient_type).first
    end

    @template_content = nil
    if @recipient
      @template_content = Templates::NotificationTemplate.new(notification).build(@recipient.email_content)
    end

  end

end
