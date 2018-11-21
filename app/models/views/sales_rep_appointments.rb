class Views::SalesRepAppointments
  # Decoration / View methods for display of various admin details
  attr_reader :sales_rep
  attr_reader :user

  def initialize(sales_rep, timeframe = nil, user = nil, office = nil)
    @sales_rep = sales_rep
    @timeframe = timeframe
    @user = user
    @office = office
  end

  def upcoming_by_date
    # Grouped appointments by date
    if @office
      appointments = @sales_rep.appointments.where("appointment_on >= ? and appointment_on <= ?", 
        (Time.zone.now - 2.weeks),(Time.zone.now + 2.weeks)).where(:office_id => @office.id).where.not(status: 
        ["deleted", "inactive", "pending", "draft"]).order(appointment_on: :asc, starts_at: :asc).select{|appt| appt.office && appt.office.activated?}
    else
      if @timeframe
        appointments = @sales_rep.appointments.select{|appt| ['completed', 'active'].include?(appt.status) &&
          @timeframe.include?(appt.appointment_on)}.sort_by{|appt| [appt.appointment_on, appt.starts_at(true)]}.select{|appt| appt.office && appt.office.activated?}
          
      else
        appointments = @sales_rep.appointments.where("appointment_on >= ? and appointment_on <= ?", Time.zone.now.beginning_of_month, 
          (Time.zone.now.end_of_month)).where.not(status:
           ["deleted", "inactive", "pending", "draft"]).order(appointment_on: :asc, starts_at: :asc).select{|appt| appt.office && appt.office.activated?}
      end
    end
    groupings = appointments.group_by { |a| short_date(a.appointment_on) }

    groupings
  end

  #used for order history calendar
  def past_events(return_count = nil)
    # Flattened appointments array with no date groupings

    events = []
    @timeframe.each do |day|
      day_appointments = @sales_rep.appointments.select{|appt| (appt.completed?) && appt.appointment_on == day && appt.orders.select{|order| order.active? ||
        order.completed?}.any? &&
          ((appt.appointment_on == Time.now.to_date) ? (appt.appointment_time(true) < Time.now.in_time_zone(appt.office.timezone)) : true) &&
          appt.office && appt.office.activated?}
      day_appointments.each_with_index do |app, index|
        name = (app.appointment_slot) ? app.appointment_slot.name : ''
        class_name = app.appointment_calendar_key
        id = app.appointment_slot ? app.appointment_slot.id : nil
        events << {id: id, title: name, start: app.appointment_time(true), end: app.appointment_end_time(true), className: "past-order", date: day}
        break if return_count && ((index + 1) >= return_count)
      end
    end
    events
  end

  def past_orders
    appointments = @sales_rep.appointments.select{|appt| appt.office && appt.office.activated? && ['completed'].include?(appt.status) &&
          @timeframe.include?(appt.appointment_on) && appt.orders.select{|order| order.active? ||
        order.completed?}.any?  &&
          ((appt.appointment_on == Time.now.to_date) ? (appt.appointment_time(true) < Time.now.in_time_zone(appt.office.timezone)) : true)}
          .sort_by{|appt| [appt.appointment_on, appt.starts_at(true)]}

    groupings = appointments.group_by { |a| short_date(a.appointment_on) }

    groupings
  end

  def upcoming_by_events(return_count = nil)
    # Flattened appointments array with no date groupings

    events = []
    return events if !@sales_rep
    @timeframe.each do |day|
      day_appointments = @sales_rep.appointments.select{|appt| appt.appointment_on == day && ['active', 'completed'].include?(appt.status)}
      day_appointments.each_with_index do |app, index|
        name = (app.appointment_slot) ? app.appointment_slot.name : ''
        class_name = app.appointment_calendar_key
        id = app.appointment_slot ? app.appointment_slot.id : nil
        events << {id: id, title: name, start: app.appointment_time(true), end: app.appointment_end_time(true), className: class_name, date: day}
        break if return_count && ((index + 1) >= return_count)
      end
    end
    events
  end


  def upcoming_by_events_api(return_count = nil)
    # Flattened appointments array with no date groupings

    events = []
    @timeframe.each do |day|
      day_appointments = @sales_rep.appointments.where("appointment_on = ?", day).where.not(status: ['inactive', 'deleted'])
      day_appointments.each_with_index do |app, index|
      	start_date_time = (app.starts_at.on app.appointment_on)
      	end_date_time = nil
      	if(app.ends_at != nil)
      		end_date_time = app.ends_at.on app.appointment_on
      	end
        name = (app.appointment_slot) ? app.appointment_slot.name : ''
        class_name = (start_date_time < Time.now - 1.day) ? 'past' : 'booked'
        total_staff_count = nil
        if(app.appointment_slot.present?)
        	total_staff_count = app.appointment_slot.total_staff_count
        end
        events << {slot_id: app.appointment_slot_id, appointment_id: app.id, total_staff_count: total_staff_count, title: name, start: app.appointment_time(true), end: app.appointment_end_time(true), 
                   className: class_name, rep_notes: app.rep_notes, office_notes: app.office_notes, office_confirmed: app.office_confirmed, rep_confirmed: app.rep_confirmed, restaurant_confirmed: app.restaurant_confirmed, status: app.status, will_supply_food: app.will_supply_food, bring_food_notes: app.bring_food_notes, office: app.office_info, orders: app.orders_with_restaurant, diet_restrictions: app.diet_restrictions_api}
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
