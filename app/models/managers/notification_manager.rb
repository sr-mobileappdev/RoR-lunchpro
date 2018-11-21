class Managers::NotificationManager
  attr_reader :event
  attr_reader :errors

  # -- For queuing up notifications based on actions in the system

  def self.trigger_notifications(category_cids, objects = [], options = {})
    # see: forms/admin_appointment.rb and controllers/admin/sales_reps_controller
    # as example places where this is method currently called
    return if category_cids.count == 0
    begin # Trap exceptions so as not to impede user experience

      object_options = {}
      objects.each do |obj|
        object_options[:office] = obj if obj.kind_of?(Office)
        object_options[:sales_rep] = obj if obj.kind_of?(SalesRep)
        object_options[:sales_rep_partner] = obj if obj.kind_of?(SalesRepPartner)
        object_options[:user] = obj if obj.kind_of?(User)
        object_options[:restaurant] = obj if obj.kind_of?(Restaurant)
        object_options[:order_review] = obj if obj.kind_of?(OrderReview)
        object_options[:order] = obj if obj.kind_of?(Order)
        object_options[:appointment_slot] = obj if obj.kind_of?(AppointmentSlot)
        object_options[:appointment] = obj if obj.kind_of?(Appointment)
        object_options[:order_transaction] = obj if obj.kind_of?(OrderTransaction)
      end

      category_cids.each do |cid|
        manager = Managers::NotificationManager.queue_new(cid)
        manager.build(object_options.merge(options))
      end

    rescue Exception => ex
      @errors = [] if @errors
      @errors << ex
      Rollbar.error(ex)
    end

  end

  #used so i can instantiate a NotificationManager object and catch errors
  def cron_trigger_notifications(category_cids, objects = [], options = {})
    self.class.trigger_notifications(category_cids, objects, options)
  end

  # -- -- -- --



  def self.queue_new(category_cid)
    Managers::NotificationManager.new(category_cid)
  end

  def self.process_new(start_timeframe_ago, processed_by)
    manager = Managers::NotificationManager.new
    manager.process_for_timeframe((Time.zone.now - 3.days)..(Time.zone.now - start_timeframe_ago), processed_by)

    manager
  end

  def initialize(category_cid = nil)
    @errors = []
    if category_cid.present?
      unless @event = NotificationEvent.find_by_category_cid(category_cid)
        Rollbar.warning("Attempting to access a notification, but no matching category_cid found (#{category_cid})")
      end
    end
  end


  # -- Methods used for checking then delivering notifications

  def process_for_timeframe(timeframe_range, processed_by)
    #only grab top 100 notifs to process
    uri = URI.parse("https://wapi.onereach.com/api/triggermessage/Sms/3yIu96Mw5aagao")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    pending = Notification.includes(:notification_event).unsent.where(queued_at: timeframe_range).order(:created_at).limit(20)
    if pending.select{|p| [402, '402'].include?(p.notification_event.category_cid)}.count >= 2
      pending = pending.sort_by{|p| [402, '402'].include?(p.notification_event.category_cid) ? 0 : 1}[0...4]
    end

    pending.each do |pending_notif|
      next if pending_notif.related_objects["office_id"].present? && !Office.find(pending_notif.related_objects["office_id"]).activated?
      pending_notif.status_summary ||= {}
      if pending_notif.delay_minutes > 0
        queue_time = pending_notif.queued_at + pending_notif.delay_minutes.minutes
        next unless queue_time < Time.zone.now
      end

      pending_notif.notified_at = Time.now
      pending_notif.save

      if pending_notif.user && pending_notif.is_web_enabled? # <-- This is NOT determined by user preference. Everything is on
        # Post actioncable notification
        pending_notif.status_summary["web_sent"] = "sent"

        template_content = nil
        if pending_notif.notification_event
          recipient = pending_notif.notification_event.notification_event_recipients.where(recipient_type: pending_notif.user.notification_recipient_type, status: 'active').first
          if recipient
            template_content = Templates::NotificationTemplate.new(pending_notif).build(recipient.content)
            pending_notif.web_summary = template_content
          end
        end

        #Managers::ActioncableManager.new("notification", "admin_notifications_#{pending_notif.user_id}").broadcast({ message: template_content || pending_notif.title, badge_count: pending_notif.user.notifications.visible.count })
      else
        pending_notif.status_summary["web_sent"] = "user_disabled"
      end

      if pending_notif.is_sms_enabled?
        # Send SMS notification
        pending_notif.status_summary["sms_sent"] = "sent"

        if pending_notif.related_objects["to_sms"] && !pending_notif.user
          pending_notif.status_summary["sms_to"] = pending_notif.related_objects["to_sms"] ? pending_notif.related_objects["to_sms"] : 'Missing SMS Phone'
        else
          pending_notif.status_summary["sms_to"] = (pending_notif.to_sms) ? pending_notif.to_sms : 'Missing SMS Phone'
        end

        begin

          if pending_notif.related_objects["non_lp_sales_rep_id"].present?
            sms_manager = Notifications::SMS.new(pending_notif.notification_event, "sales_rep", pending_notif, http)
            sms_manager.send!(pending_notif.related_objects["to_sms"])
          else
            sms_manager = Notifications::SMS.new(pending_notif.notification_event, pending_notif.user_prefs.user_notification_type, pending_notif, http)
            sms_manager.send!(pending_notif.to_sms)
          end
        rescue Exception => ex
          error_message = "Unable to send sms message."
          pending_notif.status_summary["sms_sent"] = "error"
          pending_notif.status_summary["sms_errors"] = ex
        end
      else
        pending_notif.status_summary["sms_sent"] = "user_disabled"
      end

      if pending_notif.is_email_enabled?
        # Send Email-based notification
        pending_notif.status_summary["email_sent"] = "sent"
        if pending_notif.related_objects["to_address"] && !pending_notif.user
          pending_notif.status_summary["email_to"] = pending_notif.related_objects["to_address"] ? pending_notif.related_objects["to_address"] : 'Missing Email'
        else
          pending_notif.status_summary["email_to"] = (pending_notif.to_email) ? pending_notif.to_email : 'Missing Email'
        end
        begin
          #NotificationMailer.notification(pending_notif, pending_notif.user).deliver!
          NotificationMailer.notification(pending_notif, processed_by).deliver!
        rescue Exception, SparkPostRails::DeliveryException => ex

          error_message = ex
          if ex.kind_of?(SparkPostRails::DeliveryException)
            if ex.service_code == "1902"
              error_message += " User has an invalid or non-existant email address."
            end
          end
          pending_notif.status_summary["email_sent"] = "error"
          pending_notif.status_summary["email_errors"] = error_message
        end
      else
        pending_notif.status_summary["email_sent"] = "user_disabled"
      end

      pending_notif.save

    end
  end



  # -- Methods used for building notification objects

  def build(options = {})

    return unless @event
    #return if ['100'].include?(@event.category_cid) # This list of "special" notification categories (currently only category 100) cannot be triggered in this manner

    users = determine_notification_targets(@event, options)

    users.each do |u|
      build_notification_for_user(@event, u, build_event_object_hash(options))
    end
  end

  def self.send_invite!(user, sent_by_user)

    # Sends initial system invite message to the user, appropriately based upon their user space
    # Raise an exception if somehow we've lost our required notification template(s)
    notification_event = NotificationEvent.where(category_cid: 100).first

    raise "Missing required system template for invitation" if !notification_event


    user.invite!(sent_by_user) do |u|
      u.skip_invitation = true
    end

    recipient = nil
    case user.space
      when "space_sales_rep"
        recipient = notification_event.notification_event_recipients.where(recipient_type: 'sales_rep', status: 'active').first
      when "space_admin"
        recipient = notification_event.notification_event_recipients.where(recipient_type: 'admin', status: 'active').first
      when "space_office"
        recipient = notification_event.notification_event_recipients.where(recipient_type: 'office', status: 'active').first
      when "space_restaurant"
        recipient = notification_event.notification_event_recipients.where(recipient_type: 'restaurant', status: 'active').first
    end

    raise "Missing required system notification event recipient for #{user.space}" unless recipient

    to_email = user.email

    begin
      InvitationMailer.invite(user, to_email, recipient).deliver!
    rescue Exception, SparkPostRails::DeliveryException => ex
      return false
    end

    user.invitation_sent_at = Time.now
    user.save

    return true
  end



private

  def build_event_object_hash(options)

    related = {}
    related[:office_id] = (options[:office]) ? options[:office].id : nil
    related[:appointment_slot_id] = (options[:appointment_slot]) ? options[:appointment_slot].id : nil
    related[:appointment_id] = (options[:appointment]) ? options[:appointment].id : nil
    related[:order_id] = (options[:order]) ? options[:order].id : nil
    related[:order_review_id] = (options[:order_review]) ? options[:order_review].id : nil
    related[:sales_rep_partner_id] = (options[:sales_rep_partner]) ? options[:sales_rep_partner].sales_rep.id : nil
    related[:sales_rep_id] = (options[:sales_rep]) ? options[:sales_rep].id : nil
    related[:restaurant_id] = (options[:restaurant]) ? options[:restaurant].id : nil
    related[:order_transaction_id] = (options[:order_transaction]) ? options[:order_transaction].id : nil
    related[:user_id] = (options[:user]) ? options[:user].id : nil
    related[:previous_tip_amount] = (options[:previous_tip_amount]) ? options[:previous_tip_amount] : nil
    related[:entity] = (options[:entity]) ? options[:entity] : nil
    related[:poc] = (options[:poc]) ? options[:poc] : nil
    related[:order_tranx_error] = (options[:order_tranx_error]) ? options[:order_tranx_error] : nil
    related[:order_tranx_time] = (options[:order_tranx_time]) ? options[:order_tranx_time] : nil
    related[:include_sample_text] = (options[:include_sample_text]) ? options[:include_sample_text] : nil
    related
  end

  def build_notification_for_user(event, user, related_objects)
    recipient = event.notification_event_recipients.active.where(recipient_type: user.notification_recipient_type).first
    if user.try(:space) && user.space == 'space_sales_rep' && user.sales_rep
      related_objects = related_objects.merge(user.sales_rep.determine_notification_trigger_url(event, related_objects))
    elsif user.try(:space) && user.space == 'space_office'
      related_objects = related_objects.merge(user.user_office.determine_notification_trigger_url(event, related_objects))
    elsif user.try(:space) && user.space == 'space_restaurant'
      related_objects = related_objects.merge(user.user_restaurant.determine_notification_trigger_url(event, related_objects))
    elsif !user.try(:space) && user.kind_of?(RestaurantPoc)
      related_objects = related_objects.merge({to_address: user.email, restaurant_poc: true})
      user = nil

    # if user object is a SalesRep without user
    elsif !user.try(:space) && user.kind_of?(SalesRep)
      related_objects = related_objects.merge({non_lp_sales_rep_id: user.id, to_address: user.email("business", false), to_sms: user.phone_record})
      user = nil
    end

    return unless recipient
    office = Office.where(id: related_objects[:office_id]).first
    if office && !office.activated?
      queued_at = nil
    else
      queued_at = Time.zone.now
    end
    Notification.create!( user: user,
                          title: recipient.title,
                          notification_event_id: recipient.notification_event_id,
                          priority: recipient.priority,
                          related_objects: related_objects,
                          queued_at: queued_at )
  end

  def determine_notification_targets(event, options)

    users = []
    recipients = []
    if options[:recipient_types]
      # Send only to certain recipient types
      recipients = event.notification_event_recipients.active.where(recipient_type: options[:recipient_types])
    else
      # Send to all recipients targetted for this
      recipients = event.notification_event_recipients.active
    end
    recipients.each do |r|
      case r.recipient_type
        when "office"
          users += find_office_users(options[:office], options)
        when "admin"
          users += find_admin_users(options[:user])
        when "sales_rep"
          users += find_sales_rep_user(options[:sales_rep], options)
        when "restaurant"
          users += find_restaurant_users(options[:restaurant], options)
          # @TODO add restaurant notices
      end
    end
    # In case of appointment_slots, if the notification needs to go to all related sales reps...
    if options[:appointment_slot] && options[:related_sales_reps].present?
      users += find_sales_rep_user_by_group(options[:related_sales_reps])
    end
    # In case of offices, if the notification needs to go to all related sales reps...
    if options[:office] && options[:related_sales_reps].present?
      users += find_sales_rep_user_by_group(options[:related_sales_reps])
    end

    return users.compact # Clear out any nils that may have slipped in
  end

  def find_office_users(office = nil, options)
    return [] unless office && office.kind_of?(Office)

    #this is used for invitations
    if options[:user].present?
      return [options[:user]] if options[:user].kind_of?(User)
      []
    else
      return office.users.active
    end
  end

  def find_sales_rep_user(sales_rep = nil, options = nil)
    return [] unless sales_rep && sales_rep.kind_of?(SalesRep)
    if options && options[:user].present?
      return [options[:user]] if options[:user].kind_of?(User)
      []
    else
      if !sales_rep.user
        return [sales_rep]
      else
        return [sales_rep.user]
      end
    end
  end

  def find_restaurant_users(restaurant = nil, options)
    return [] unless restaurant && restaurant.kind_of?(Restaurant)
    if options[:user].present?
      return [options[:user]] if options[:user].kind_of?(User)
      []
    else
      if @event.category_cid.to_i == 406
        rest_users = restaurant.users.active.to_a + restaurant.restaurant_pocs.active.to_a
      else
        rest_users = restaurant.users.active.to_a
      end
      if restaurant.headquarters && restaurant.headquarters.managers.any?
        rest_users += restaurant.headquarters.managers
      end
      return rest_users
    end
  end

  def find_sales_rep_user_by_group(sales_reps = [])
    reps = []
    sales_reps.each do |rep|
      reps += find_sales_rep_user(rep)
    end
    return reps
  end

  def find_admin_users(user = nil)
    #return User.space_admin.active.all
    ##TODO - Determien master list of admin users who will receive emails##
    if [100, 418].include?(event.category_cid.to_i) && user.space != "space_admin"
      return []
    else
      return User.space_admin.select{|user| user.active?}
    end
  end

end
