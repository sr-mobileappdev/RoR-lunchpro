class Templates::AppointmentTemplate < Templates::BaseTemplate
  attr_reader :appointment

  def initialize(obj = nil)
    @object_type = obj.class
    @appointment = obj
  end

  def tags
    return [] if !@appointment
    {
      day_and_time: 'day_and_time',
      date: 'appointment_date',
      short_date: 'appointment_short_date',
      cancel_appointment_url: 'cancel_appointment_url',
      name: 'slot_name',
      cancellation_reason: 'cancellation_reason',
      expected_staff_count: 'expected_staff_count',
      view_order_recommendation_url: 'view_order_recommendation_url',
      view_cuisine_recommendation_url: 'view_cuisine_recommendation_url',
      recommended_cuisines: 'recommended_cuisines',
      requested_drugs: 'requested_drugs',
      office_notes: 'office_notes',
      place_food_order_url: 'place_food_order_url',
      expected_providers: 'expected_providers',
      office_url: 'office_url',
      recommend_food_url: 'recommend_food_url',
      notify_standby_list_url: 'notify_standby_list_url',
      book_appointment_url: 'book_appointment_url',
      leave_review_url: 'leave_review_url',
      rep_footer_buttons: 'rep_footer_buttons',
      cancelled_by_full_name: 'cancelled_by_full_name',
      is_lp: 'is_lp',
      non_lp: 'non_lp',
      confirm_appointment_url: 'confirm_appointment_url',
      sample_request_message: 'sample_request_message',
      is_not_sample?: 'is_not_sample?',
      delivery_time: 'delivery_time',
      reminder_email_content: 'reminder_email_content',
      reminder_sms_content: 'reminder_sms_content'
    }
  end

  def __reminder_email_content
    html = "" 
    if !@appointment.rep_confirmed_at
      if !@appointment.food_ordered 
        html += "Let me help you Skip some steps! #{@appointment.sales_rep.first_name}, your appointment on #{ApplicationController.helpers.short_date(@appointment.appointment_on)} at #{@appointment.office.name}
        has not been confirmed! Please click <a href='#{UrlHelpers.current_rep_calendars_url}'>here</a> to confirm. Place your food order <a href='#{UrlHelpers.current_rep_calendars_url}'>here</a> now."    
      else
        html += "Let me help you Skip some steps! #{@appointment.sales_rep.first_name}, your appointment on #{ApplicationController.helpers.short_date(@appointment.appointment_on)} at #{@appointment.office.name}
        has not been confirmed! However, your food order has been placed. Click <a href='#{UrlHelpers.current_rep_calendars_url}''>here</a> to confirm."    
      end
    else
      if !@appointment.food_ordered
        html += "Let the office know what you're bringing! #{@appointment.sales_rep.first_name}, your appointment on #{ApplicationController.helpers.short_date(@appointment.appointment_on)} at #{@appointment.office.name}
        is confirmed. Please click <a href='#{UrlHelpers.current_rep_calendars_url}'>here</a> to place your food order now"
      else
        html += "You're all set! #{@appointment.sales_rep.first_name}, your appointment on #{ApplicationController.helpers.short_date(@appointment.appointment_on)} at #{@appointment.office.name} is confirmed.
        Your food order has been placed. Click <a href='#{UrlHelpers.current_rep_calendars_url}'>here</a> here to review."
      end
    end
    html.html_safe
  end

  def __reminder_sms_content
    html = ""
    if !@appointment.rep_confirmed_at
      if !@appointment.food_ordered
        html += "Your appointment on #{ApplicationController.helpers.short_date(@appointment.appointment_on)} at #{@appointment.office.name} has not been confirmed. Log in to confirm! https://bit.ly/2NiMvx4"
      else
        html += "Your appointment on #{ApplicationController.helpers.short_date(@appointment.appointment_on)} at #{@appointment.office.name} has not been confirmed. Your food order has been placed. Log in to confirm or review! https://bit.ly/2NiMvx4"
      end
    else
      if !@appointment.food_ordered
        html += "Your appointment on #{ApplicationController.helpers.short_date(@appointment.appointment_on)} at #{@appointment.office.name} is confirmed. Log in to order food! https://bit.ly/2NiMvx4"
      else
        html += "Your appointment on #{ApplicationController.helpers.short_date(@appointment.appointment_on)} at #{@appointment.office.name} is confirmed. Your food order has been placed. Log in to review. https://bit.ly/2NiMvx4"
      end
    end
    html.html_safe
  end

  def __is_not_sample?
    (@appointment.appointment_slot.present? && @appointment.appointment_slot.slot_type != 'sample') || !@appointment.appointment_slot_id
  end

  def __is_lp
    @appointment.appointment_slot.present?
  end

  def __non_lp
    !@appointment.appointment_slot.present?
  end

  def __cancelled_by_full_name
    user = User.find(@appointment.cancelled_by_id) if @appointment.cancelled_by_id
    if user
      user.display_name
    end
  end

  def __requested_drugs
    ApplicationController.helpers.drugs(Drug.find(@appointment.samples_requested))
  end

  def __recommended_cuisines
    ApplicationController.helpers.appointment_cuisines(@appointment.cuisines)
  end

  def __leave_review_url    
    if @appointment.sales_rep
      UrlHelpers.rep_appointment_url(@appointment)
    else
      UrlHelpers.office_appointment_url(@appointment)
    end
  end

  def __book_appointment_url
    UrlHelpers.book_standby_rep_appointment_url(@appointment)
  end
  def __notify_standby_list_url
    UrlHelpers.office_appointment_url(@appointment)
  end
  def __recommend_food_url
    UrlHelpers.recommendation_office_appointment_url(@appointment)
  end

  def __office_url
    UrlHelpers.rep_offices_url(office: @appointment.office_id)
  end
  def __cancel_appointment_url
    UrlHelpers.rep_appointment_url(@appointment)
  end

  def __confirm_appointment_url
    UrlHelpers.rep_appointment_url(@appointment)
  end

  def __place_food_order_url
    if @appointment.sales_rep
      UrlHelpers.select_restaurant_rep_appointment_url(@appointment)
    else
      UrlHelpers.select_restaurant_office_appointment_url(@appointment)
    end
  end

  def __view_cuisine_recommendation_url
    UrlHelpers.policies_rep_appointments_url(office_id: @appointment.office.id, appointment_id: @appointment.id)
  end

  def __rep_footer_buttons
    html = ""
    if !@appointment.food_ordered? && @appointment.appointment_slot && @appointment.appointment_slot.slot_type != 'sample'
      html += "<br /><a href='" + UrlHelpers.select_restaurant_rep_appointment_url(@appointment) + "' class='btn-primary'>Order Food</a>"
    end
    html += "<br /><a href='" + UrlHelpers.rep_appointment_url(@appointment) + "' class='btn-primary'>View Appointment</a>"
    html.html_safe
  end

  def __view_order_recommendation_url
    UrlHelpers.order_recommendation_rep_appointment_url(@appointment)
  end

  def __expected_staff_count
    @appointment.appointment_slot.total_staff_count([], @appointment.appointment_on)
  end

  def __expected_providers
    @appointment.appointment_slot.total_staff_count([], @appointment.appointment_on) - @appointment.appointment_slot.staff_count
  end

  def __appointment_short_date
    ApplicationController.helpers.short_date(@appointment.appointment_on)
  end

  def __appointment_date
    ApplicationController.helpers.standard_date(@appointment.appointment_on)
  end

  def __day_and_time
    ApplicationController.helpers.long_date(@appointment.appointment_time_in_zone)
  end

  def __delivery_time
    ApplicationController.helpers.long_date_minus_15(@appointment.appointment_time_in_zone)
  end

  def __slot_name
    (@appointment.appointment_slot) ? @appointment.appointment_slot.name : 'Appointment'
  end

  def __cancellation_reason
    if @appointment.cancel_reason.present?
      'They needed to cancel because: <i>'.html_safe + @appointment.cancel_reason + '</i>. Here\'s their phone number if you\'d like to follow up'.html_safe
    else
      "They didn't give a reason. Here's their phone number if you'd like to call and ask"
    end
  end

  def __sample_request_message
    if @@options && @@options['include_sample_text'].present? && @@options['include_sample_text'] == "true"
      "They left a message: #{@appointment.office_notes} -"
    else
      "They did not leave a message."
    end
  end

end
