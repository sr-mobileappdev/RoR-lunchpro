class Views::RestaurantOrders
  # Decoration / View methods for display of various admin details
  attr_reader :restaurant
  attr_reader :user
  attr_reader :consolidated

  def initialize(restaurant, timeframe = nil, consolidated = false)
    @restaurant = restaurant
    @timeframe = timeframe
    @consolidated = consolidated
  end

  def confirmed_orders_by_date
    # Restaurant has orders, can be called using .orders. Each individual order has an appointment (.appointment), but restaurants DO NOT.
    # Appointment has the attribute of 'restaurant_confirmed_at'. If nil, unconfirmed, else confirmed.
    if @restaurant
      if @timeframe        
        if @consolidated
          orders = @restaurant.consolidated_orders
        else
          orders = @restaurant.orders
        end
        orders = orders.select{|order| ['active'].include?(order.status) &&
          order.confirmed? &&
          order.appointment.present? &&
          @timeframe.include?(order.appointment.appointment_on)}.sort_by{|order| [order.appointment.appointment_on, order.appointment.starts_at(true)]}
      else
        if @consolidated
          orders = @restaurant.consolidated_orders
        else
          orders = @restaurant.orders
        end
        orders = orders.select{|order| ['active'].include?(order.status) && order.appointment.present? && order.confirmed?}.sort_by{|order| [order.appointment.appointment_on, order.appointment.starts_at(true)]}
      end
    end
    groupings = orders.group_by { |o| short_date(o.order_date) }

    groupings
  end

  def upcoming_by_date
    # Grouped orders by date
    if @restaurant
      if @timeframe
        orders = @restaurant.orders.select{|order| ['active'].include?(order.status) &&
          @timeframe.include?(order.appointment.appointment_on)}.sort_by{|order| [order.appointment.appointment_on, order.appointment.starts_at(true)]}
      else
        orders = @restaurant.orders.where("", Time.zone.now.beginning_of_month, (Time.zone.now.end_of_month)).where.not(status: ["deleted", "inactive", "pending", "draft"]).sort_by{|order| [order.appointment.appointment_on, order.appointment.starts_at(true)]}
      end
    end
    groupings = orders.group_by { |o| short_date(o.order_date) }

    groupings
  end

  def unconfirmed_orders_by_date
    if @restaurant
      if @timeframe
        if @consolidated
          orders = @restaurant.consolidated_orders
        else
          orders = @restaurant.orders.where("recommended_by_id is null")
        end
        orders = orders.select{|order| ['active'].include?(order.status) &&
          !order.confirmed? &&
          order.appointment.present? &&
          @timeframe.include?(order.appointment.appointment_on)}.sort_by{|order| [order.appointment.appointment_on, order.appointment.starts_at(true)]}
      else
        if @consolidated
          orders = @restaurant.consolidated_orders
        else
          orders = @restaurant.orders.where("recommended_by_id is null")
        end
        orders = orders.select{|order| ['active'].include?(order.status) && order.appointment.present? && !order.confirmed?}.sort_by{|order| [order.appointment.appointment_on, order.appointment.starts_at(true)]}
      end
    end
    groupings = orders.group_by { |o| short_date(o.order_date) }

    groupings
  end

  def past_orders
    if @restaurant
      if @timeframe
        if @consolidated
          orders = @restaurant.consolidated_orders('completed')
        else
          orders = @restaurant.orders
        end
        orders = orders.select{|order| ['completed'].include?(order.status) &&
          @timeframe.include?(order.appointment.appointment_on)}.sort_by{|order| [order.appointment.appointment_on, order.appointment.starts_at(true)]}

      else
        if @consolidated
          orders = @restaurant.consolidated_orders('completed')
        else
          orders = @restaurant.orders
        end
        orders = orders.select{|order| ['completed'].include?(order.status)}.sort_by{|order| [order.appointment.appointment_on, order.appointment.starts_at(true)]}
      end
    end
    groupings = orders.group_by { |o| short_date(o.order_date) }

    groupings
  end

  def all_orders
    if @restaurant
      if @timeframe
        orders = @restaurant.orders.select{|order| @timeframe.include?(order.appointment.appointment_on)}.sort_by{|order| [order.appointment.appointment_on, order.appointment.starts_at(true)]}
      else
        orders = @restaurant.orders.sort_by{|order| [order.appointment.appointment_on, order.appointment.starts_at(true)]}
      end
    end
    groupings = orders.group_by { |o| short_date(o.order_date) }

    groupings
  end

  def upcoming_by_events(return_count = nil)
    # Flattened orders array with no date groupings

    event = []
    @timeframe.each do |day|
      day_orders = @restaurant.orders.active.select{|order| order.appointment.appointment_on == day}
      day_orders.each_with_index do |order, index|
        name = (order.appointment.appointment_slot) ? order.appointment.appointment_slot.name : ''
        class_name = order.appointment.appointment_calendar_key
        id = order.appointment.appointment_slot ? order.appointment.appointment_slot.id : nil
        events << {id: id, title: name, start: order.order_time, end: order.appointment.appointment_end_time, className: class_name, date: day}
        break if return_count && ((index + 1) >= return_count)
      end
    end
    events
  end

  def past_events(return_count = nil)
    events = []
    @timeframe.each do |day|
      if @consolidated
        orders = @restaurant.consolidated_orders('completed')
      else
        orders = @restaurant.orders
      end
      day_orders = orders.select{|order| order.completed? && order.appointment.appointment_on == day &&
          ((order.appointment.appointment_on == Time.now.to_date) ? (order.appointment.appointment_time(true) < Time.now.in_time_zone(order.restaurant.timezone)) : true)}
      day_orders.each_with_index do |order, index|
        name = (order.appointment.appointment_slot) ? order.appointment.appointment_slot.name : ''
        id = order.id
        events << {id: id, title: name, start: order.appointment.appointment_time, end: order.appointment.appointment_end_time, className: "past-order", date: day}
        break if return_count && ((index + 1) >= return_count)
      end
    end
    events
  end

  def upcoming_by_events_api(return_count = nil)
    # Flattened appointments array with no date groupings
    # Flattened appointments array with no date groupings

    event = []
    @timeframe.each do |day|
      day_orders = @restaurant.orders.active.select{|order| order.appointment.appointment_on == day}
      day_orders.each_with_index do |order, index|
        name = (order.appointment.appointment_slot) ? order.appointment.appointment_slot.name : ''
        class_name = order.appointment.appointment_calendar_key
        id = order.appointment.appointment_slot ? order.appointment.appointment_slot.id : nil
        events << {id: id, title: name, start: order.order_time, end: order.appointment.appointment_end_time, className: class_name, date: day}
        break if return_count && ((index + 1) >= return_count)
      end
    end
    events
  end

private

  def short_date(date, default = nil)
    return date if date && date.kind_of?(String)
    if default
      return default unless date
    end

    date.strftime("%a, %b %e")
  end

end
