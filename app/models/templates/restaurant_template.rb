class Templates::RestaurantTemplate < Templates::BaseTemplate
  attr_reader :restaurant

  def initialize(obj = nil)
    @object_type = obj.class
    @restaurant = obj
  end

  def tags
    return [] if !@restaurant
    {
      todays_orders_table: 'todays_orders_table',
      unconfirmed_orders_table: 'unconfirmed_orders_table',
      unconfirmed_orders_table_admin: 'unconfirmed_orders_table_admin',
      name: "name",
      display_location: 'display_location',
      postal_code: 'postal_code',
      poc_name: 'poc_name',
      poc_email: 'poc_email',
      poc_phone_number: 'poc_phone_number',
      confirm_order_url: 'confirm_order_url'
    }
  end

  def __poc_name
    if @@options && @@options['poc'].present?
      @@options['poc']['full_name']
    else
      @restaurant.contact_name
    end
  end

  def __poc_email
    if @@options && @@options['poc'].present?
      @@options['poc']['email_address']
    else
      @restaurant.contact_email
    end
  end

  def __poc_phone_number
    if @@options && @@options['poc'].present?
      ApplicationController.helpers.format_phone_number_string(@@options['poc']['phone_number'])
    else
      @restaurant.contact_phone
    end
  end

  def __unconfirmed_orders_table
    ac = ActionController::Base.new()
    ah = ApplicationController.helpers
    orders = @restaurant.all_unconfirmed_orders.select{ |x| x.appointment.present? && x.appointment.appointment_on >= Date.today }
    ##should style table in email content and render <trs> in partial
    table = ac.render_to_string(partial: 'shared/notification_partials/unconfirmed_orders', :layout => false, locals:{orders: orders, ah: ah}, :formats => [:html])
    table.html_safe
  end

  def __unconfirmed_orders_table_admin
    ac = ActionController::Base.new()
    ah = ApplicationController.helpers
    orders = @restaurant.all_unconfirmed_orders
    ##should style table in email content and render <trs> in partial
    table = ac.render_to_string(partial: 'shared/notification_partials/unconfirmed_orders_admin', :layout => false, locals:{orders: orders, ah: ah}, :formats => [:html])
    table.html_safe
  end

  def __todays_orders_table
    ac = ActionController::Base.new()
    ah = ApplicationController.helpers
    orders = @restaurant.orders_for_today
    ##should style table in email content and render <trs> in partial
    table = ac.render_to_string(partial: 'shared/notification_partials/todays_orders', :layout => false, locals:{orders: orders, ah: ah}, :formats => [:html])
    table.html_safe

  end

  def __confirm_order_url
    if ['408', '207', '406', '121', '119', '203'].include?(@@notification_event_id.to_s)
      #@order.appointment.confirm_for_restaurant!
      resp = UrlHelpers.new_user_session_url
      resp
    end
  end
end
