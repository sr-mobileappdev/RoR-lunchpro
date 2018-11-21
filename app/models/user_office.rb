class UserOffice < ApplicationRecord
  include LunchproRecord

  belongs_to :user
  belongs_to :office



  def determine_notification_trigger_url(event, related_objects)
    return '#' if !related_objects
    trigger_obj = {trigger_url: '#', modal: false, modal_size: nil}
    case event.category_cid.to_i
    when 204
      trigger_obj[:trigger_url] = UrlHelpers.office_appointment_path(related_objects[:appointment_id], is_modal: true, standby: true)
      trigger_obj[:modal] = true
    when 205
      trigger_obj[:trigger_url] = UrlHelpers.office_appointment_path(related_objects[:appointment_id], is_modal: true, standby: true)
      trigger_obj[:modal] = true
    when 409
      trigger_obj[:trigger_url] = UrlHelpers.office_appointment_path(related_objects[:appointment_id], is_modal: true)
      trigger_obj[:modal] = true      
      trigger_obj[:modal_size] = 'sm' if related_objects[:appointment_id] && 
        Appointment.find(related_objects[:appointment_id]).internal?
    when 410
      trigger_obj[:trigger_url] = UrlHelpers.appointments_until_office_preferences_path(is_modal: true)
      trigger_obj[:modal] = true      
      trigger_obj[:modal_size] = 'sm'
    when 414
      trigger_obj[:trigger_url] = UrlHelpers.office_appointment_path(related_objects[:appointment_id], is_modal: true)
      trigger_obj[:modal] = true
    end
    trigger_obj
  end
end
