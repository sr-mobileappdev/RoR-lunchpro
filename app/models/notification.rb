class Notification < ApplicationRecord
  include LunchproRecord

  # Simulated records, for notification testing w/o writing junk to the database
  attr_reader :sim_appointment, :sim_order, :sim_office, :sim_sales_rep, :sim_restaurant
  attr_writer :sim_appointment, :sim_order, :sim_office, :sim_sales_rep, :sim_restaurant

  belongs_to :user
  belongs_to :notification_event
  belongs_to :relatable, polymorphic: true

  def self.visible
    notifs = active.where(removed_at: nil).where.not(notified_at: nil, web_summary: [nil, '']).order(notified_at: :desc, created_at: :desc)
    notifs.select{|notif| notif.notification_event.notification_event_recipients.select{|notifer|
      notifer.active? && notifer.is_web_default &&
      NotificationEventRecipient.recipient_types.key(notifer.recipient_type).delete(' ') == notif.user.entity.class.name}.any? || notif.user.space == 'space_admin'}
  end

  def self.unread
    active.where(read_at: nil)
  end

  def self.unsent
    active.where(notified_at: nil)
  end

  def self.priorities
    {"1 - High" => '1', "2 - Normal" => '2', "3 - Low" => '3'}
  end

  def latest_notified_date
    notified_at || queued_at || created_at
  end

  def web_title(recipient_type)
  	begin
    if notification_event && notification_event.notification_event_recipients.where(recipient_type: recipient_type, status: 'active').count > 0
      notification = Notifications::Web.new(self, notification_event, recipient_type)
      notification.title
    else
      ""
    end
    rescue Exception => error
    	Rollbar.error(error.message)
    	""
    end
  end

  def to_email # What email should this be sent to?    

    if user && user.space == 'space_sales_rep' && user.sales_rep
      user.sales_rep.email('business', false) || user.email
    elsif user && user.space != 'space_sales_rep'
      user.email
    elsif !user && related_objects["to_address"].present?
      related_objects["to_address"]
    end
  end

  def to_sms # What phone should this be sent to?
    if user.space == 'space_sales_rep' && user.sales_rep
      user.sales_rep.phone_record('business')
    else
      (user.primary_phone.present?) ? user.primary_phone : nil
    end
  end

  # Does this notification's user elect to receive this notification?
  def is_web_enabled?
    true
  end

  def is_sms_enabled?
    return true if (!user && related_objects["to_sms"].present?)
    (user_prefs && user_prefs.via_sms && user_prefs.via_sms["#{self.notification_event.category_cid}"]) ? true : false
  end

  def is_email_enabled?
    return true if user && user.space_admin? || (!user && related_objects["to_address"].present?)# Right now admin users don't get to unsubscribe from anything... sorry admin users
    (user_prefs && user_prefs.via_email && user_prefs.via_email["#{self.notification_event.category_cid}"].to_i == 1) ? true : false
  end

  def user_prefs
    return nil if !user
    @prefs ||= user.user_notification_prefs.active.where(notifiable_type: nil).first
  end


  # Various potential related objects -- these all could be nil, so nil should be handled

  def appointment
    related_object_of(Appointment) || sim_appointment
  end

  def order
    related_object_of(Order) || sim_order
  end

  def office
    related_object_of(Office) || sim_office
  end

  def sales_rep
    related_object_of(SalesRep) || sim_sales_rep
  end

  def restaurant
    related_object_of(Restaurant) || sim_restaurant
  end

  def sales_rep_partner
    related_object_of(SalesRepPartner)
  end

  def order_transaction
    related_object_of(OrderTransaction)
  end

  def self.dismiss_path(user, notif)
    path = "#"
    return path if !user || !notif

    case user.space
    when 'space_sales_rep'
      path = UrlHelpers.remove_rep_notification_path(notif)
    when 'space_office'
      path = UrlHelpers.remove_office_notification_path(notif)
    when 'space_restaurant'
      path = UrlHelpers.remove_restaurant_notification_path(notif)
    end
  end

  def delivery_summary
    summary_items = []
    if status_summary && status_summary.kind_of?(Hash)
      if status_summary["sms_sent"] && status_summary["sms_sent"] == "sent"
        summary_items << "SMS sent to #{status_summary["sms_to"]}"
      elsif status_summary["sms_sent"] && status_summary["sms_sent"] == "user_disabled"
        summary_items << "SMS disabled for this notification and user"
      end

      if status_summary["email_sent"] && status_summary["email_sent"] == "sent"
        summary_items << "Email sent to #{status_summary["email_to"]}"
      elsif status_summary["email_sent"] && status_summary["email_sent"] == "user_disabled"
        summary_items << "Email disabled for this notification and user"
      end

    else
      ""
    end
    if summary_items.any?
      summary_items.join("<br/>").html_safe
    else
      ""
    end
  end

  # -- Search / Query Scoping
  def self.scope_params_for(scope_strings = [])
    params = {}

    scope_strings.each do |scope|
      case scope
        when "active"
          params["status"] = "active"
        when "notified"
          params["status"] = ["active","completed"]
          params["notified_at"] = {operator: "lteq", condition: Time.zone.now}
      end
    end

    params
  end
  # --

  def user_email
    (user) ? user.email : ""
  end

  def self.__columns
    cols = {delivery_summary: 'Delivery Summary', user_email: 'User Email'}
    hidden_cols = []
    columns = self.__default_columns.merge(cols).except(*hidden_cols)
  end

  def trigger_url
    related_objects["trigger_url"] || '#'
  end

  def trigger_modal?
    related_objects["modal"] || false
  end

  def modal_size
    related_objects["modal_size"] || nil
  end

  def subject(subject)
    if subject.include? '{{order.order_number}}'
      order = Order.find(related_objects["order_id"]) if related_objects["order_id"]
      return subject if !order
      subject.gsub! '{{order.order_number}}', "#{order.order_number}"
    elsif subject.include? '{{office.name}}'
      office = Office.find(related_objects["office_id"]) if related_objects["office_id"]
      return subject if !office
      subject.gsub! '{{office.name}}', "#{office.name}"
    end    
  end

  def parsed_title(title)
    if title.include? '{{order.order_number}}'
      order = Order.find(related_objects["order_id"]) if related_objects["order_id"]
      return title if !order
      title.gsub! '{{order.order_number}}', "#{order.order_number}"
    elsif title.include? '{{office.name}}'
      office = Office.find(related_objects["office_id"]) if related_objects["office_id"]
      return title if !office
      title.gsub! '{{office.name}}', "#{office.name}"
    else
      return title
    end
  end

private

  def related_object_of(object_type)
    unless related_objects && related_objects.kind_of?(Hash)
      return nil
    end

    case object_type.to_s
      when "Appointment"
        (related_objects["appointment_id"]) ? Appointment.where(id: related_objects["appointment_id"]).first : nil
      when "SalesRepPartner"
        (related_objects["sales_rep_partner_id"]) ? SalesRep.where(id: related_objects["sales_rep_partner_id"]).first : nil
      when "Order"
        (related_objects["order_id"]) ? Order.where(id: related_objects["order_id"]).first : nil
      when "Office"
        (related_objects["office_id"]) ? Office.where(id: related_objects["office_id"]).first : nil
      when "SalesRep"
        (related_objects["sales_rep_id"]) ? SalesRep.where(id: related_objects["sales_rep_id"]).first : nil
      when "Restaurant"
        (related_objects["restaurant_id"]) ? Restaurant.where(id: related_objects["restaurant_id"]).first : nil
      when "OrderTransaction"
        (related_objects["order_transaction_id"]) ? OrderTransaction.where(id: related_objects["order_transaction_id"]).first : nil
      else
        nil
    end
  end

end
