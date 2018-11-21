class Views::Notices
  # Decoration / View methods for display of various admin details
  attr_reader :notices
  attr_reader :activation_notices

  def self.for_office(office)
    raise "Attempting to init notice view for office without passing an office" unless office && office.kind_of?(Office)
    new(office)
  end

  def self.for_sales_rep(sales_rep)
    raise "Attempting to init notice view for sales rep without passing a sales rep" unless sales_rep && sales_rep.kind_of?(SalesRep)
    new(sales_rep)
  end

  def self.for_restaurant(restaurant)
    raise "Attempting to init notice view for sales rep without passing a restaurant" unless restaurant && restaurant.kind_of?(Restaurant)
    new(restaurant)
  end

  def self.for_notification_event(notification_event)
    raise "Attempting to init notice view for notification event without passing a valid object" unless notification_event && notification_event.kind_of?(NotificationEvent)
    new(notification_event)
  end

  def self.for_notification_event_recipient(notification_event_recipient)
    raise "Attempting to init notice view for notification event recipient without passing a valid object" unless notification_event_recipient && notification_event_recipient.kind_of?(NotificationEventRecipient)
    new(notification_event_recipient)
  end

  def initialize(record)
    @record = record
    @notices = []
    @activation_notices = []
  end

  # - The Good Stuff
  def all
    if @record && @record.kind_of?(Office)
      office_notices
    elsif @record && @record.kind_of?(SalesRep)
      sales_rep_notices
    elsif @record && @record.kind_of?(NotificationEvent)
      notification_event_notices
    elsif @record && @record.kind_of?(NotificationEventRecipient)
      notification_event_recipient_notices
    elsif @record && @record.kind_of?(Restaurant)
      restaurant_notices
    else
      []
    end
  end

  def activation
    if @record && @record.kind_of?(Office)
      office_activation_notices
    elsif @record && @record.kind_of?(SalesRep)
      sales_rep_activation_notices
    elsif @record && @record.kind_of?(Restaurant)
      restaurant_activation_notices
    else
      []
    end
  end

private

  def sales_rep_notices
    # Gather up applicable notice events related to sales reps
    @notices << has_valid_login?
    @notices << is_deactivated?("Sales rep")
    @notices.compact
  end

  def office_activation_notices
    @activation_notices << {message: "Office policies, food preferences and delivery instructions must be set."} unless @record.has_policies?
    @activation_notices << {message: "At least one or more appointment slots must be added to the office calendar."} unless @record.appointment_slots.active.count > 0
    @activation_notices << {message: "Calendar must be open for appointments into some point in the future."} unless @record.appointments_until.present? && @record.appointments_until > (Time.zone.now.to_date + 2.days)
    @activation_notices << {message: "There must be at least one registered user (Office Manager)."} unless @record.users.active.count > 0 && @record.manager.present?
    @activation_notices.compact
  end

  def office_notices
    # Gather up applicable notice events related to offices
    # [{message: 'This office is the best', priority: 1, relatable: Provider.all.first}]
    []
  end

  def restaurant_activation_notices
    @activation_notices << {message: "No menus and/or menu items exist, yet. You must upload or create at least one menu and have at least one menu item active."} if @record.menus.count == 0 || @record.menu_items.active.count == 0
    @activation_notices << {message: "Default delivery fee, late cancellation fee, and processing fee options must be set."} unless @record.fees_set?
    @activation_notices << {message: "Minimum order price, maximum amount of people per order, as well order cutoff time and date must be set."} unless @record.order_limitations_set?
    @activation_notices << {message: "There must be at least one Restaurant User."} unless @record.users.count > 0
    @activation_notices << {message: "There must be a connected bank account."} unless @record.bank_accounts.active.count > 0
    @activation_notices << {message: "There must be a delivery radius set."} unless @record.delivery_distance.present?
    @activation_notices.compact
  end

  def restaurant_notices
    # Gather up applicable notice events related to offices
    # [{message: 'This office is the best', priority: 1, relatable: Provider.all.first}]
    @notices << has_valid_restaurant_login?
    @notices << is_deactivated?("Restaurant")
    @notices.compact
  end

  def notification_event_notices
    @notices << is_inactive?("Notification")
    @notices.compact
  end

  def notification_event_recipient_notices
    @notices << is_inactive?("Notification")
    @notices.compact
  end


  def has_valid_restaurant_login?
    if @record.user_restaurants && @record.user_restaurants.count > 0 && @record.user_restaurants[0].user && @record.user_restaurants[0].user.id && @record.user_restaurants[0].user.email
      nil
    else
      {message: 'Missing or expired web login. Restaurant cannot log in to their account until this is fixed.', priority: 2, relatable: nil}
    end
  end

  def has_valid_login?
    if @record.user && @record.user.id && @record.user.email
      nil
    else
      {message: 'Missing or expired web login. Sales rep cannot log in to their account until this is fixed.', priority: 2, relatable: nil}
    end
  end

  def is_deactivated?(noun = "Record")
    (@record.respond_to?(:deactivated_at) && @record.deactivated_at) ? {message: "#{noun} is currently deactivated.", priority: 1, relatable: nil} : nil
  end

  def is_inactive?(noun = "Record")
    (@record.respond_to?(:status) && @record.status == "inactive") ? {message: "#{noun} is currently inactive.", priority: 1, relatable: nil} : nil
  end

end
