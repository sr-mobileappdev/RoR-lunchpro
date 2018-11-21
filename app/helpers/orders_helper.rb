module OrdersHelper

  def check_for_appointment(office = nil, sales_rep = nil)
    appt = sales_rep.appointments.active.where(:office_id => office.id).select{|appt|
      appt.appointment_time(true) > Time.now.in_time_zone(appt.office.timezone) && !appt.active_order}.sort_by{|appt| appt.appointment_time(true)}.first

    if appt && appt.orders.active.count == 0
      "data-modal='true' data-modal-size=md href=" + show_existing_rep_appointment_path(appt.id, is_modal: true) + ""
    else
      "data-modal='true' data-modal-size=sm href=" + prompt_schedule_rep_appointments_path(office: office.id, is_modal: true) + ""
    end
  end

  def order_rep_notes(order)
    if order.rep_notes.present?
      order.rep_notes
    else
      "You did not leave any notes."
    end
  end

  def order_office_notes(order)
    if order.office_notes.present?
      order.office_notes
    else
      "There were no notes left for this order."
    end
  end

  def restaurant_confirmed(order)
    return "" if !order
    order.confirmed? ? "Confirmed" : "Unconfirmed"
  end

  def csv_order_status(order)
    return "" if !order
    if order.cancelled?
      return 'Cancelled'
    elsif order.completed?
      return 'Completed'
    elsif order.appointment.restaurant_confirmed
      return 'Confirmed'
    elsif !order.appointment.restaurant_confirmed
      return "Unconfirmed"
    else
      return "--"
    end
  end

  def csv_order_delivery_info(order, admin = false)
    info = ""
    return info unless order && order.appointment && order.appointment.office
    office = order.appointment.office
    if admin
    else
      info = "#{office.name} \n#{office.address_line1}, #{office.address_line2} \n#{office.display_city_state_postal} \n#{format_phone_number_string(office.phone)}"
    end
    info
  end


  def csv_order_customer_info(order)
    info = ""
    return info unless order && order.appointment
    if order.customer && order.customer.kind_of?(SalesRep)
      info = "#{order.customer_name} \n#{order.customer.company ? order.customer.company.name : '--'} \n#{order.customer_email} \n#{format_phone_number_string(order.customer_phone)}"
    else
      info = "#{order.customer_name} \n#{order.customer_email} \n#{format_phone_number_string(order.customer_phone)}"
    end
    info
  end

  def display_sub_item_cost(item = nil)
    return nil if !item
    if item.quantity > 1
      "(#{item.quantity} x #{precise_currency_value(item.unit_cost_cents)})"
    else
      "(#{precise_currency_value(item.unit_cost_cents)})"
    end
  end

  def confirmed?
    if order.appointment.restaurant_confirmed_at != nil
      return true
    else
      return false
    end
  end

  def delivery_date_and_time(order)
    "#{long_date(order.appointment_timestamp)}"
  end

  def order_office_manager(office)
    if office.manager
      "#{office.manager.display_name}"
    else
      "No Office Manager"
    end
  end

  def primary_contact_phone(poc)
    if poc
      name_number = "#{poc.display_name}"
      if poc.phone
        name_number += ": #{format_phone_number_string(poc.phone)}"
      end
    else
      name_number = "No Primary Contact Set"
    end
  end

  def secondary_contact_phone(user)
    if user
      name_number = "#{user.display_name}"
      if user.primary_phone
        name_number += ": #{format_phone_number_string(user.primary_phone)}"
      end
    else
      name_number = "No Secondary Contact Set"
    end
  end

end
