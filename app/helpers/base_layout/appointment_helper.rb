module BaseLayout::AppointmentHelper

  def appointment_summary(appointment)
    "#{appointment.description}, #{long_date(appointment.appointment_time_in_zone)}"
  end

  def appointment_rep_summary(sales_rep)
    html = "<a class='jump' href='#{admin_sales_rep_path(sales_rep)}'>#{sales_rep.display_name}</a>"
    html.html_safe
  end

  def appointment_office(office)
    html = "<a class='jump' href='#{admin_office_path(office)}'>#{office.name}</a>"
    html.html_safe
  end

  def appointment_restaurant(rest)
    html = "<a class='jump' href='#{admin_restaurant_path(rest)}'>#{rest.name}</a>"
    html.html_safe
  end

  def csv_appointment_status(appt)
    return "" if !appt
    if appt.completed? || appt.past?
      return "Completed"
    elsif appt.cancelled?
      return "Cancelled"
    elsif appt.rep_confirmed
      return "Confirmed"
    elsif appt.sales_rep_confirmable?
      return "Pending"
    else
      "--"
    end
  end

  def csv_appointment_name(appt)
    return "" if !appt
    if appt.appointment_slot
      appt.appointment_slot.name 
    else
      "NA"
    end
  end

  def csv_appointment_cancelled_by(appt)
    return "" if !appt
    if appt.cancelled?
      appt.canceller.entity.class.name if appt.canceller && appt.canceller.entity
    else
      '--'
    end
  end

  def csv_appointment_cancellation_reason(appt)
    return "" if !appt
    if appt.cancelled? && appt.cancel_reason.present?
      appt.cancel_reason
    else
      '--'
    end
  end

  def csv_appointment_cancelled_on(appt)
    return "" if !appt
    if appt.cancelled?
      csv_long_date(appt.cancelled_at)
    else
      '--'
    end
  end


  def appointment_office_link(appt)
    return if !appt.office.active?
    if current_user.sales_rep.offices_sales_reps.where(:office_id => appt.office.id, :status => 'active').present?
      rep_offices_path(id: appt.office.id)
    else
      new_rep_office_path(id: appt.office.id)
    end
  end

  def drugs(cuisines)
    if cuisines.count == 1
      cuisines.first.brand
    elsif cuisines.count == 2
      cuisines.first.brand + " and " + cuisines.second.brand
    elsif cuisines.count > 2
      string = ""
      cuisines.each_with_index do |cuisine, index|
        if index == cuisines.count - 2
           string += cuisine.brand
           string += ", and "
        elsif index == cuisines.count - 1
           string += cuisine.brand
        else
          string += cuisine.brand
          string += ", "
        end      
      end
      string
    else
      "No Drugs Selected"
    end
  end

  def appointment_cuisines(cuisines)
    if cuisines.count == 1
      cuisines.first.name
    elsif cuisines.count == 2
      cuisines.first.name + " or " + cuisines.second.name
    elsif cuisines.count > 2
      string = ""
      cuisines.each_with_index do |cuisine, index|
        if index == cuisines.count - 2
           string += cuisine.name
           string += ", or "
        elsif index == cuisines.count - 1
           string += cuisine.name
        else
          string += cuisine.name
          string += ", "
        end      
      end
      string
    else
      "No Cuisines Selected"
    end
  end

  def byo_button_text(appt)
    return "Bring Your Own" if !appt
    if appt.will_supply_food
      "Edit Byo"
    else
      "Bring Your Own"
    end
  end
end
